//
//  NotificationService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import Foundation
import Moya

enum NotificationError: Error, LocalizedError {
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

final class NotificationService {
    static let shared = NotificationService()
    private let provider = MoyaProvider<NotificationAPI>()

    private init() {}

    // MARK: - 알림 목록 조회

    func getNotifications(page: Int = 0, size: Int = 20) async throws -> NotificationPageData {
        let response = try await requestWithRefresh(.getNotifications(page: page, size: size))

        guard (200..<300).contains(response.statusCode) else {
            throw NotificationError.serverError("서버 오류 (\(response.statusCode))")
        }

        let decoded = try JSONDecoder().decode(NotificationPageResponse.self, from: response.data)

        guard decoded.success, let data = decoded.data else {
            throw NotificationError.serverError(decoded.message)
        }

        return data
    }

    // MARK: - 읽지 않은 알림 수

    func getUnreadCount() async throws -> Int64 {
        let response = try await requestWithRefresh(.getUnreadCount)

        guard (200..<300).contains(response.statusCode) else {
            throw NotificationError.serverError("서버 오류 (\(response.statusCode))")
        }

        let decoded = try JSONDecoder().decode(UnreadCountResponse.self, from: response.data)

        guard decoded.success, let data = decoded.data else {
            throw NotificationError.serverError(decoded.message)
        }

        return data.count
    }

    // MARK: - 알림 읽음 처리

    func markAsRead(id: Int64) async throws {
        let response = try await requestWithRefresh(.markAsRead(id: id))

        guard (200..<300).contains(response.statusCode) else {
            throw NotificationError.serverError("읽음 처리에 실패했습니다.")
        }
    }

    // MARK: - 전체 읽음 처리

    func markAllAsRead() async throws {
        let response = try await requestWithRefresh(.markAllAsRead)

        guard (200..<300).contains(response.statusCode) else {
            throw NotificationError.serverError("전체 읽음 처리에 실패했습니다.")
        }
    }

    // MARK: - 401 → refresh → 1회 재시도

    private func requestWithRefresh(_ target: NotificationAPI) async throws -> Response {
        let firstResult = await provider.requestAsync(target)

        switch firstResult {
        case .success(let response):
            if response.statusCode == 401 {
                do {
                    _ = try await AuthService.shared.refreshAccessToken()
                } catch {
                    TokenStorage.forceLogout()
                    throw NotificationError.unauthorized
                }
                let retryResult = await provider.requestAsync(target)
                switch retryResult {
                case .success(let retryResponse):
                    if retryResponse.statusCode == 401 {
                        TokenStorage.forceLogout()
                        throw NotificationError.unauthorized
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
