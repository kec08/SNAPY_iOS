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
    case termsAgreement
    case registerEmail
    case registerPassword
    case registerPhone
    case registerInfo
    case registerProfileImage
    case registerComplete
    case contactSync
    case onboarding
    case oauthInfo        // 구글 로그인 후 핸들/이름 설정
    case oauthProfile     // 구글 로그인 후 프로필/배너 이미지
    case oauthPhone       // 구글 로그인 후 전화번호 등록
    case oauthContactSync // 구글 로그인 후 연락처 동기화
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
                        screen = .termsAgreement
                    },
                    onGoogleLoginSuccess: {
                        screen = .oauthPhone
                    },
                    onGoogleLoginExistingUser: {
                        authVM.isOAuthLogin = false
                        screen = .main
                    },
                    onAppleLoginSuccess: {
                        screen = .oauthPhone
                    },
                    onAppleLoginExistingUser: {
                        authVM.isOAuthLogin = false
                        screen = .main
                    }
                )
                .environmentObject(authVM)

            case .snapyLogin:
                SnapyLoginView(
                    onBack: {
                        screen = .login
                    },
                    onLoginTap: {
                        Task {
                            await authVM.login()
                            if authVM.isLoggedIn {
                                screen = .main
                            }
                        }
                    },
                    onRegisterTap: {
                        screen = .termsAgreement
                    }
                )
                .environmentObject(authVM)

            case .termsAgreement:
                TermsAgreementView(
                    onBack: {
                        screen = .login
                    },
                    onAgreed: {
                        screen = .registerEmail
                    }
                )

            case .registerEmail:
                EmailView(
                    onBack: {
                        screen = .termsAgreement
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
                        Task {
                            await signUpVM.register()
                            if signUpVM.isRegistered {
                                screen = .registerPhone
                            }
                        }
                    }
                )
                .environmentObject(signUpVM)

            case .registerPhone:
                PhoneView(
                    onBack: {
                        screen = .registerPassword
                    },
                    onSignNextTap: {
                        Task {
                            if !signUpVM.registerPhone.isEmpty && !signUpVM.verificationCode.isEmpty {
                                do {
                                    try await ProfileService.shared.updatePhone(
                                        signUpVM.registerPhone,
                                        code: signUpVM.verificationCode
                                    )
                                    print("[SignUp] 전화번호 등록 성공")
                                } catch {
                                    print("[SignUp] 전화번호 등록 실패: \(error)")
                                }
                            }
                            screen = .registerInfo
                        }
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
                            await signUpVM.saveInfo()
                            if signUpVM.errorMessage == nil {
                                screen = .registerProfileImage
                            }
                        }
                    }
                )
                .environmentObject(signUpVM)

            case .registerProfileImage:
                RegisterProfileImageView(onNext: {
                    screen = .contactSync
                })

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
                
            case .oauthPhone:
                OAuthPhoneView(onNext: {
                    screen = .oauthInfo
                }, onBack: {
                    screen = .login
                })

            case .oauthInfo:
                OAuthInfoView(onNext: {
                    screen = .oauthProfile
                })
                .environmentObject(authVM)

            case .oauthProfile:
                RegisterProfileImageView(onNext: {
                    screen = .oauthContactSync
                })

            case .oauthContactSync:
                ContactSyncView(onDoneTap: {
                    authVM.isOAuthLogin = false
                    screen = .main
                })

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
        // 1) access token이 아직 유효하면 프로필 확인
        if TokenStorage.isAccessTokenValid() {
            print("[AutoLogin] access token 유효")
            let destination = await checkProfileCompletion()
            screen = destination
            return
        }

        // 2) refresh token이 있으면 재발급 시도
        if TokenStorage.refreshToken != nil {
            do {
                _ = try await AuthService.shared.refreshAccessToken()
                print("[AutoLogin] 토큰 재발급 성공")
                let destination = await checkProfileCompletion()
                screen = destination
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

    /// 프로필 완성도 확인 → 미완성 시 해당 단계로 이동
    func checkProfileCompletion() async -> AppScreen {
        do {
            let profile = try await ProfileService.shared.fetchMyProfile()
            UserDefaults.standard.set(profile.handle, forKey: "myHandle")

            // handle이 비어있거나 임시값(user_로 시작)이면 → 전화번호부터
            if profile.handle.isEmpty || profile.handle.hasPrefix("user_") {
                print("[AutoLogin] 프로필 미완성 (handle=\(profile.handle)) → oauthPhone")
                return .oauthPhone
            }

            print("[AutoLogin] 프로필 완성 → 메인")
            return .main
        } catch {
            print("[AutoLogin] 프로필 조회 실패: \(error) → oauthPhone")
            return .oauthPhone
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
