//
//  ReportService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/26/26.
//

import Foundation
import Moya

final class ReportService {
    static let shared = ReportService()
    private let provider = MoyaProvider<ReportAPI>()

    private init() {}

    // MARK: - 신고 접수

    func report(targetType: String, targetId: Int64? = nil, userHandle: String? = nil, reason: String) async throws {
        let response = try await requestWithRefresh(.create(
            targetType: targetType,
            targetId: targetId,
            userHandle: userHandle,
            reason: reason
        ))
        print("[ReportService] statusCode: \(response.statusCode)")
        print("[ReportService] body: \(String(data: response.data, encoding: .utf8) ?? "nil")")
        guard (200..<300).contains(response.statusCode) else {
            throw ReportError.serverError(extractMessage(from: response))
        }
    }

    // MARK: - 토큰 리프레시 포함 요청

    private func requestWithRefresh(_ target: ReportAPI) async throws -> Response {
        let firstResult = await provider.requestAsync(target)
        switch firstResult {
        case .success(let response):
            if response.statusCode == 401 {
                _ = try await AuthService.shared.refreshAccessToken()
                let retryResult = await provider.requestAsync(target)
                switch retryResult {
                case .success(let retryResponse):
                    return retryResponse
                case .failure(let error):
                    throw error
                }
            }
            return response
        case .failure(let error):
            throw error
        }
    }

    private func extractMessage(from response: Response) -> String {
        if let decoded = try? JSONDecoder().decode(BaseResponse<String?>.self, from: response.data) {
            return decoded.message
        }
        // 서버 에러 응답 형식 (status, error, message, timestamp)
        if let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any],
           let message = json["message"] as? String {
            return message
        }
        return "알 수 없는 오류"
    }
}

// MARK: - Error

enum ReportError: Error, LocalizedError {
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .serverError(let msg):
            return msg
        }
    }
}
