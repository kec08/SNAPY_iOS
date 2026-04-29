//
//  StoryService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/19/26.
//

import Foundation
import Moya

enum StoryError: Error, LocalizedError {
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

final class StoryService {
    static let shared = StoryService()
    private let provider = MoyaProvider<StoryAPI>()

    private init() {}

    // MARK: - 스토리 목록

    func fetchStories() async throws -> [StoryListData] {
        let response = try await requestWithRefresh(.fetchStories)
        guard (200..<300).contains(response.statusCode) else {
            throw StoryError.serverError("서버 오류 (\(response.statusCode))")
        }
        let decoded = try JSONDecoder().decode(StoryListResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw StoryError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 스토리 상세

    func fetchDetail(storyId: Int) async throws -> StoryDetailData {
        let response = try await requestWithRefresh(.fetchDetail(storyId: storyId))
        guard (200..<300).contains(response.statusCode) else {
            throw StoryError.serverError("서버 오류 (\(response.statusCode))")
        }
        let decoded = try JSONDecoder().decode(StoryDetailResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw StoryError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 좋아요 토글

    func toggleLike(storyId: Int, type: AlbumType) async throws -> StoryLikeData {
        let response = try await requestWithRefresh(.toggleLike(storyId: storyId, type: type))
        guard (200..<300).contains(response.statusCode) else {
            throw StoryError.serverError("서버 오류 (\(response.statusCode))")
        }
        let decoded = try JSONDecoder().decode(StoryLikeToggleResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw StoryError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 401 → refresh → 1회 재시도

    private func requestWithRefresh(_ target: StoryAPI) async throws -> Response {
        let firstResult = await provider.requestAsync(target)

        switch firstResult {
        case .success(let response):
            if response.statusCode == 401 {
                do {
                    _ = try await AuthService.shared.refreshAccessToken()
                } catch {
                    TokenStorage.forceLogout()
                    throw StoryError.unauthorized
                }
                let retryResult = await provider.requestAsync(target)
                switch retryResult {
                case .success(let retryResponse):
                    if retryResponse.statusCode == 401 {
                        TokenStorage.forceLogout()
                        throw StoryError.unauthorized
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
