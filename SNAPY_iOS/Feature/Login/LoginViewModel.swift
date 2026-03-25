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

//    private let authService = AuthService.shared

    var isLoginValid: Bool {
        !loginEmail.isEmpty && !loginPassword.isEmpty
    }

    @MainActor
    func checkAuthStatus() {
        // 임시: 인증 없이 온보딩으로 이동
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.authFlow = .onboarding
        }
    }

    func login() async {
        guard isLoginValid else { return }
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        // 임시: 짧은 지연 후 로그인 처리
        try? await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            let mockUser = User(
                id: 1,
                email: loginEmail,
                handle: "silver_c.ld",
                username: "김은찬",
                password: "",
                profileImageUrl: nil,
                backgroundImageUrl: nil,
                phone: nil,
                postCount: 5,
                friendCount: 13,
                streakCount: 2
            )
            currentUser = mockUser
            isLoggedIn = true
            authFlow = .main
            isLoading = false
        }
    }

    @MainActor
    func completeRegistration() {
        isLoggedIn = true
        authFlow = .main
    }

    func logout() async {
        await MainActor.run {
            isLoggedIn = false
            authFlow = .loginSelection
            loginEmail = ""
            loginPassword = ""
        }
    }
}
