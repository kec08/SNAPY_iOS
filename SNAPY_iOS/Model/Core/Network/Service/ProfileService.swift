//
//  ProfileService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import Foundation
import UIKit
import Moya

final class ProfileService {
    static let shared = ProfileService()
    private let provider = MoyaProvider<ProfileAPI>()

    private init() {}

    // MARK: - 내 프로필 조회

    func fetchMyProfile() async throws -> ProfileData {
        let response = try await requestWithRefresh(.fetchMyProfile)
        guard (200..<300).contains(response.statusCode) else {
            throw ProfileError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(ProfileResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw ProfileError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 타인 프로필 조회

    func fetchUserProfile(handle: String) async throws -> ProfileData {
        let response = try await requestWithRefresh(.fetchUserProfile(handle: handle))
        guard (200..<300).contains(response.statusCode) else {
            throw ProfileError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(ProfileResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw ProfileError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 프로필 이미지 변경

    func updateProfileImage(_ image: UIImage) async throws -> String? {
        print("[ProfileService] 프로필 이미지 업로드")
        let response = try await requestWithRefresh(.updateProfileImage(image: image))
        print("[ProfileService] 응답 코드 \(response.statusCode)")
        if let body = String(data: response.data, encoding: .utf8) { print("[ProfileService] 응답 \(body)") }
        guard (200..<300).contains(response.statusCode) else {
            throw ProfileError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(ProfileImageResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw ProfileError.serverError(decoded.message)
        }
        return data.profileImageUrl
    }

    // MARK: - 배경 이미지 변경

    func updateBackgroundImage(_ image: UIImage) async throws -> String? {
        print("[ProfileService] 배경 이미지 업로드")
        let response = try await requestWithRefresh(.updateBackgroundImage(image: image))
        print("[ProfileService] 응답 코드 \(response.statusCode)")
        if let body = String(data: response.data, encoding: .utf8) { print("[ProfileService] 응답 \(body)") }
        guard (200..<300).contains(response.statusCode) else {
            throw ProfileError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(BackgroundImageResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw ProfileError.serverError(decoded.message)
        }
        return data.backgroundImageUrl
    }

    // MARK: - 설정 조회

    func fetchSettings() async throws -> UserSettingData {
        let response = try await requestWithRefresh(.fetchSettings)
        guard (200..<300).contains(response.statusCode) else {
            throw ProfileError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(UserSettingResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw ProfileError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 피드 & 스토리 공개 범위 변경

    func updateFeedVisibility(_ visibility: Visibility) async throws {
        let response = try await requestWithRefresh(.updateFeedVisibility(visibility))
        guard (200..<300).contains(response.statusCode) else {
            throw ProfileError.serverError(extractMessage(from: response))
        }
    }

    // MARK: - 과거 앨범 공개 범위 변경

    func updatePastAlbumVisibility(_ visibility: Visibility) async throws {
        let response = try await requestWithRefresh(.updatePastAlbumVisibility(visibility))
        guard (200..<300).contains(response.statusCode) else {
            throw ProfileError.serverError(extractMessage(from: response))
        }
    }

    // MARK: - 방명록 조회

    func fetchGuestbook(handle: String) async throws -> [GuestbookResponseData] {
        let response = try await requestWithRefresh(.fetchGuestbook(handle: handle))
        guard (200..<300).contains(response.statusCode) else {
            throw ProfileError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(GuestbookListResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw ProfileError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 방명록 작성

    func postGuestbook(handle: String, image: UIImage) async throws -> GuestbookCreateResponseData {
        let response = try await requestWithRefresh(.postGuestbook(handle: handle, image: image))
        print("[ProfileService] 방명록 작성 응답 코드 \(response.statusCode)")
        if let body = String(data: response.data, encoding: .utf8) {
            print("[ProfileService] 방명록 작성 응답 \(body)")
        }
        guard (200..<300).contains(response.statusCode) else {
            throw ProfileError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(GuestbookCreateResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw ProfileError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 401 재시도

    private func requestWithRefresh(_ target: ProfileAPI) async throws -> Response {
        let firstResult = await provider.requestAsync(target)
        switch firstResult {
        case .success(let response):
            if response.statusCode == 401 {
                do {
                    _ = try await AuthService.shared.refreshAccessToken()
                } catch {
                    TokenStorage.forceLogout()
                    throw ProfileError.unauthorized
                }
                let retryResult = await provider.requestAsync(target)
                switch retryResult {
                case .success(let r):
                    if r.statusCode == 401 { throw ProfileError.unauthorized }
                    return r
                case .failure(let e): throw e
                }
            }
            return response
        case .failure(let error):
            throw error
        }
    }

    // MARK: - 에러 메시지 추출

    private func extractMessage(from response: Response) -> String {
        if let spring = try? JSONDecoder().decode(SpringError.self, from: response.data) {
            return spring.message ?? "서버 오류 (\(response.statusCode))"
        }
        return "서버 오류 (\(response.statusCode))"
    }

    private struct SpringError: Decodable {
        let message: String?
    }
}

enum ProfileError: Error, LocalizedError {
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "로그인이 필요합니다."
        case .serverError(let msg): return msg
        }
    }
}
