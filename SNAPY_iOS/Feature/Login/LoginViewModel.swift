//
//  LoginViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import Foundation
import SwiftUI
import Combine
import GoogleSignIn

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

    func googleLogin() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            guard let windowScene = await MainActor.run(body: {
                UIApplication.shared.connectedScenes.first as? UIWindowScene
            }),
            let rootVC = await MainActor.run(body: {
                windowScene.keyWindow?.rootViewController
            }) else {
                await MainActor.run {
                    errorMessage = "로그인 화면을 표시할 수 없습니다."
                    isLoading = false
                }
                return
            }

            let config = GIDConfiguration(clientID: "1020178958015-4hpunjp0nggtit2idai2961j14sea0dj.apps.googleusercontent.com")
            GIDSignIn.sharedInstance.configuration = config
            print("[GoogleLogin] signIn 시작")
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            print("[GoogleLogin] signIn 완료 - user: \(result.user.profile?.email ?? "nil")")
            print("[GoogleLogin] idToken 존재 여부: \(result.user.idToken != nil)")
            guard let idToken = result.user.idToken?.tokenString else {
                print("[GoogleLogin] idToken이 nil")
                await MainActor.run {
                    errorMessage = "Google 인증 토큰을 가져올 수 없습니다."
                    isLoading = false
                }
                return
            }
            print("[GoogleLogin] idToken 앞 50자: \(String(idToken.prefix(50)))")
            print("[GoogleLogin] idToken 획득, 서버 전송 시작")
            let response = try await authService.googleLogin(idToken: idToken)
            print("[GoogleLogin] 서버 응답: success=\(response.success)")

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
            print("[GoogleLogin] 에러 발생: \(error)")
            print("[GoogleLogin] 에러 설명: \(error.localizedDescription)")
            await MainActor.run {
                if error.localizedDescription.contains("canceled") || error.localizedDescription.contains("cancelled") {
                    // 사용자가 취소한 경우
                    isLoading = false
                } else {
                    errorMessage = "구글 로그인에 실패했습니다. 다시 시도해주세요."
                    isLoading = false
                }
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
