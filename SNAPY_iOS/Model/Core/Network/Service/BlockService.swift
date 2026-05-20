//
//  BlockService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/20/26.
//

import Foundation
import Moya

final class BlockService {
    static let shared = BlockService()
    private let provider = MoyaProvider<BlockAPI>()

    private init() {}

    // MARK: - 유저 차단

    func blockUser(handle: String) async throws {
        let response = try await requestWithRefresh(.blockUser(handle: handle))
        guard (200..<300).contains(response.statusCode) else {
            throw BlockError.serverError(extractMessage(from: response))
        }
    }

    // MARK: - 차단 해제

    func unblockUser(handle: String) async throws {
        let response = try await requestWithRefresh(.unblockUser(handle: handle))
        guard (200..<300).contains(response.statusCode) else {
            throw BlockError.serverError(extractMessage(from: response))
        }
    }

    // MARK: - 차단 목록 조회

    func getBlockedUsers() async throws -> [BlockedUserData] {
        let response = try await requestWithRefresh(.getBlockedUsers)
        guard (200..<300).contains(response.statusCode) else {
            throw BlockError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(BlockedUsersResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw BlockError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 토큰 리프레시 포함 요청

    private func requestWithRefresh(_ target: BlockAPI) async throws -> Response {
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
        return "알 수 없는 오류"
    }
}

// MARK: - Error

enum BlockError: Error, LocalizedError {
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "인증이 필요합니다"
        case .serverError(let msg):
            return msg
        }
    }
}
