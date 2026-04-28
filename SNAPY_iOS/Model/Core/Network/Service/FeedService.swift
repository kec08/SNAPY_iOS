//
//  FeedService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/28/26.
//

import Foundation
import Moya

enum FeedError: Error, LocalizedError {
    case unauthorized
    case serverError(String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .unauthorized:         return "로그인이 필요합니다."
        case .serverError(let msg): return msg
        case .decodingFailed:       return "응답을 해석할 수 없습니다."
        }
    }
}

final class FeedService {
    static let shared = FeedService()
    private let provider = MoyaProvider<FeedAPI>()

    private init() {}

    // MARK: - 피드 추천 (커서 기반)

    func fetchFeed(cursor: Int? = nil, size: Int = 20) async throws -> CursorResponse<FeedItemData> {
        let target: FeedAPI = .recommend(cursor: cursor, size: size)
        let response = try await requestWithRefresh(target)
        guard (200..<300).contains(response.statusCode) else {
            throw FeedError.serverError("서버 오류 (\(response.statusCode))")
        }
        let decoded = try JSONDecoder().decode(FeedResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw FeedError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 401 → refresh → 1회 재시도

    private func requestWithRefresh(_ target: FeedAPI) async throws -> Response {
        let firstResult = await provider.requestAsync(target)

        switch firstResult {
        case .success(let response):
            if response.statusCode == 401 {
                do {
                    _ = try await AuthService.shared.refreshAccessToken()
                } catch {
                    TokenStorage.clear()
                    throw FeedError.unauthorized
                }
                let retryResult = await provider.requestAsync(target)
                switch retryResult {
                case .success(let retryResponse):
                    if retryResponse.statusCode == 401 {
                        TokenStorage.clear()
                        throw FeedError.unauthorized
                    }
                    return retryResponse
                case .failure(let err):
                    throw err
                }
            }
            return response

        case .failure(let error):
            throw error
        }
    }
}
