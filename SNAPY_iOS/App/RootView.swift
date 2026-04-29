//
//  RootView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI

enum AppScreen {
    case splash
    case login
    case snapyLogin
    case registerEmail
    case registerPassword
    case registerPhone
    case registerInfo
    case registerComplete
    case contactSync
    case onboarding
    case main
}

struct RootView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var signUpVM = SiginUpViewModel()
    @State private var screen: AppScreen = .splash
    @State private var showSessionExpiredAlert = false

    var body: some View {
        ZStack {
            switch screen {
            case .splash:
                SplashView()

            case .login:
                LoginView(
                    onSnapyTap: {
                        screen = .snapyLogin
                    },
                    onRegisterTap: {
                        screen = .registerEmail
                    }
                )
            .environmentObject(authVM)

            case .snapyLogin:
                SnapyLoginView(
                    onLoginTap: {
                        Task {
                            await authVM.login()
                            if authVM.isLoggedIn {
                                screen = .main
                            }
                        }
                    },
                    onRegisterTap: {
                        screen = .registerEmail
                    }
                )
                .environmentObject(authVM)

            case .registerEmail:
                EmailView(
                    onBack: {
                        screen = .login
                    },
                    onSignNextTap: {
                        screen = .registerPassword
                    }
                )
                .environmentObject(signUpVM)

            case .registerPassword:
                PasswordView(
                    onBack: {
                        screen = .registerEmail
                    },
                    onSignNextTap: {
                        screen = .registerPhone
                    }
                )
                .environmentObject(signUpVM)

            case .registerPhone:
                PhoneView(
                    onBack: {
                        screen = .registerPassword
                    },
                    onSignNextTap: {
                        screen = .registerInfo
                    }
                )
                .environmentObject(signUpVM)

            case .registerInfo:
                InfoView(
                    onBack: {
                        screen = .registerPhone
                    },
                    onSignNextTap: {
                        Task {
                            await signUpVM.register()
                            if signUpVM.isRegistered {
                                screen = .contactSync
                            }
                        }
                    }
                )
                .environmentObject(signUpVM)

            case .contactSync:
                ContactSyncView(
                    onDoneTap: {
                        screen = .registerComplete
                    }
                )

            case .registerComplete:
                registerCompleteView(
                    onDoneTap: {
                        signUpVM.clearFields()
                        screen = .snapyLogin
                    }
                )
                .environmentObject(signUpVM)
                
            case .onboarding:
                OnboardingView(onStartTap: {
                    screen = .main
                })

            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: screen)
        .task {
            // 스플래시 최소 표시 시간
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await checkAutoLogin()
        }
        .onReceive(NotificationCenter.default.publisher(for: .didLogout)) { _ in
            // 이미 로그인 화면이면 알림 불필요
            guard screen != .login && screen != .snapyLogin && screen != .splash else { return }
            showSessionExpiredAlert = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .didManualLogout)) { _ in
            screen = .login
        }
        .alert("세션 만료", isPresented: $showSessionExpiredAlert) {
            Button("확인") {
                screen = .login
            }
        } message: {
            Text("로그인이 만료되었습니다.\n다시 로그인해주세요.")
        }
    }
}

// MARK: - 자동 로그인
private extension RootView {
    func checkAutoLogin() async {
        // 1) access token이 아직 유효하면 바로 메인
        if TokenStorage.isAccessTokenValid() {
            print("[AutoLogin] access token 유효 → 메인")
            screen = .main
            return
        }

        // 2) refresh token이 있으면 재발급 시도
        if TokenStorage.refreshToken != nil {
            do {
                _ = try await AuthService.shared.refreshAccessToken()
                print("[AutoLogin] 토큰 재발급 성공 → 메인")
                screen = .main
                return
            } catch {
                print("[AutoLogin] 토큰 재발급 실패 → 로그인")
                TokenStorage.clear()
            }
        }

        // 3) 토큰 없음 → 로그인
        print("[AutoLogin] 토큰 없음 → 로그인")
        screen = .login
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
