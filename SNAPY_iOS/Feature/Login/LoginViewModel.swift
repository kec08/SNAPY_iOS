//
//  LoginViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import Foundation
import SwiftUI
import Combine

enum AuthFlow: Equatable {
    case splash
    case onboarding
    case loginSelection
    case login
    case registerEmail
    case registerPassword
    case registerPhone
    case registerProfile
    case registerComplete
    case main
}

final class AuthViewModel: ObservableObject {
    @Published var authFlow: AuthFlow = .splash
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 로그인 입력 필드
    @Published var loginEmail = ""
    @Published var loginPassword = ""

    @Published var currentUser: User?

    private let authService = AuthService.shared

    var isLoginValid: Bool {
        !loginEmail.isEmpty && !loginPassword.isEmpty
    }

    @MainActor
    func checkAuthStatus() {
        // 저장된 토큰이 유효하면 바로 메인으로
        if TokenStorage.isAccessTokenValid() {
            isLoggedIn = true
            authFlow = .main
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.authFlow = .onboarding
            }
        }
    }

    func login() async {
        guard isLoginValid else {
            await MainActor.run {
                errorMessage = "이메일과 비밀번호를 입력해주세요."
            }
            return
        }
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            isLoggedIn = false
        }

        do {
            let response = try await authService.login(
                email: loginEmail,
                password: loginPassword
            )

            await MainActor.run {
                if response.success {
                    isLoggedIn = true
                    authFlow = .main
                } else {
                    errorMessage = response.message
                }
                isLoading = false
            }
        } catch let authError as AuthError {
            await MainActor.run {
                errorMessage = authError.localizedDescription
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "로그인에 실패했습니다. 다시 시도해주세요."
                isLoading = false
            }
        }
    }

    @MainActor
    func completeRegistration() {
        isLoggedIn = true
        authFlow = .main
    }

    func logout() async {
        do {
            try await authService.logout()
        } catch {
            print("로그아웃 에러: \(error)")
        }

        await MainActor.run {
            isLoggedIn = false
            authFlow = .loginSelection
            loginEmail = ""
            loginPassword = ""
            currentUser = nil
        }
    }
}
