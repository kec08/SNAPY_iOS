//
//  AuthService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 12/03/25.
//

import Foundation
import Moya

enum AuthError: Error, LocalizedError {
    case noRefreshToken
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .noRefreshToken:
            return "로그인이 필요합니다."
        case .serverError(let msg):
            return msg
        }
    }
}

final class AuthService {
    static let shared = AuthService()
    private let provider = MoyaProvider<AuthAPI>()

    private init() {}

    // MARK: - 로그인
    func login(email: String, password: String) async throws -> LoginResponse {
        let result = await provider.requestAsync(.login(email: email, password: password))
        switch result {
        case .success(let response):
            let decoded = try JSONDecoder().decode(LoginResponse.self, from: response.data)

            guard decoded.success, let data = decoded.data else {
                throw AuthError.serverError(decoded.message)
            }

            // accessToken 저장
            TokenStorage.accessToken = data.accessToken

            return decoded

        case .failure(let error):
            throw error
        }
    }

    // MARK: - 회원가입
    func signup(
        username: String,
        handle: String,
        email: String,
        phone: String,
        password: String
    ) async throws -> SignUpResponse {
        let result = await provider.requestAsync(
            .signup(username: username, handle: handle, email: email, phone: phone, password: password)
        )
        switch result {
        case .success(let response):
            print("[AuthService] 회원가입 응답 코드 \(response.statusCode)")
            if let body = String(data: response.data, encoding: .utf8) {
                print("[AuthService] 회원가입 응답 \(body)")
            }
            let decoded = try JSONDecoder().decode(SignUpResponse.self, from: response.data)

            guard decoded.success else {
                throw AuthError.serverError(decoded.message)
            }

            return decoded

        case .failure(let error):
            throw error
        }
    }

    // MARK: - 토큰 재발급 (RefreshToken은 쿠키에서 서버가 자동 추출)
    func refreshAccessToken() async throws -> RefreshResponse {
        let result = await provider.requestAsync(.refresh)

        switch result {
        case .success(let response):
            let decoded = try JSONDecoder().decode(RefreshResponse.self, from: response.data)

            guard decoded.success, let data = decoded.data else {
                throw AuthError.serverError(decoded.message)
            }

            // 새 accessToken 저장
            TokenStorage.accessToken = data.accessToken

            return decoded

        case .failure(let error):
            TokenStorage.clear()
            throw error
        }
    }

    // MARK: - 로그아웃
    func logout() async throws {
        let result = await provider.requestAsync(.logout)

        switch result {
        case .success(let response):
            let decoded = try JSONDecoder().decode(LogoutResponse.self, from: response.data)

            guard decoded.success else {
                throw AuthError.serverError(decoded.message)
            }

            TokenStorage.clear()

        case .failure(let error):
            TokenStorage.clear()
            throw error
        }
    }
}
