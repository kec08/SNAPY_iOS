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
            print("[AuthService] 로그인 응답 코드 \(response.statusCode)")
            if let body = String(data: response.data, encoding: .utf8) {
                print("[AuthService] 로그인 응답 \(body)")
            }

            // HTTP 에러 상태 코드 처리
            guard (200..<300).contains(response.statusCode) else {
                // Spring Boot 에러 또는 BaseResponse 형식에서 메시지 추출
                if let parsed = try? JSONDecoder().decode(BaseResponse<EmptyData>.self, from: response.data) {
                    throw AuthError.serverError(localizedLoginError(parsed.message, statusCode: response.statusCode))
                }
                if let springError = try? JSONDecoder().decode(SpringLoginError.self, from: response.data),
                   let msg = springError.message {
                    throw AuthError.serverError(localizedLoginError(msg, statusCode: response.statusCode))
                }
                throw AuthError.serverError(localizedLoginError(nil, statusCode: response.statusCode))
            }

            let decoded = try JSONDecoder().decode(LoginResponse.self, from: response.data)

            guard decoded.success, let data = decoded.data else {
                throw AuthError.serverError(localizedLoginError(decoded.message, statusCode: response.statusCode))
            }

            // accessToken 저장
            TokenStorage.accessToken = data.accessToken

            return decoded

        case .failure:
            throw AuthError.serverError("네트워크 연결을 확인해주세요.")
        }
    }

    /// 서버 에러 메시지를 한국어로 변환
    private func localizedLoginError(_ message: String?, statusCode: Int) -> String {
        let msg = message?.lowercased() ?? ""

        if statusCode == 401 || msg.contains("unauthorized") || msg.contains("invalid") || msg.contains("credentials") {
            return "이메일 또는 비밀번호가 잘못되었습니다."
        }
        if statusCode == 404 || msg.contains("not found") || msg.contains("user") {
            return "등록되지 않은 계정입니다."
        }
        if statusCode == 400 || msg.contains("bad request") {
            return "입력 정보가 올바르지 않습니다."
        }
        if statusCode == 500 {
            return "서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
        }
        if let message = message, !message.isEmpty {
            return message
        }
        return "로그인에 실패했습니다. 다시 시도해주세요."
    }

    private struct SpringLoginError: Decodable {
        let status: Int?
        let error: String?
        let message: String?
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

            // 서버 에러 상태 코드 처리
            if response.statusCode == 409 {
                // 서버 메시지 추출 시도
                if let parsed = try? JSONDecoder().decode(BaseResponse<EmptyData>.self, from: response.data) {
                    throw AuthError.serverError(parsed.message)
                }
                throw AuthError.serverError("이미 등록된 정보입니다")
            }

            guard (200..<300).contains(response.statusCode) else {
                if let parsed = try? JSONDecoder().decode(BaseResponse<EmptyData>.self, from: response.data) {
                    throw AuthError.serverError(parsed.message)
                }
                throw AuthError.serverError("서버 오류 (\(response.statusCode))")
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
