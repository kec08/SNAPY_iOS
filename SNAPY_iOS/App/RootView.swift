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
    case onboarding
    case main
}

struct RootView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var screen: AppScreen = .splash

    var body: some View {
        ZStack {
            switch screen {
            case .splash:
                SplashView()

            case .login:
                LoginView(onSnapyTap: {
                    screen = .snapyLogin
                })
                .environmentObject(authVM)

            case .snapyLogin:
                SnapyLoginView(
                    title: "SNAPY 로그인",
                    onLoginTap: {
                        screen = .onboarding
                    },
                    onRegisterTap: {
                        screen = .registerEmail
                    }
                )
                .environmentObject(authVM)

            case .registerEmail:
                EmailView(
                    title: "이메일 입력",
                    onSignNextTap: {
                        screen = .registerPassword
                    }
                )
                .environmentObject(authVM)
                
            case .registerPassword:
                PasswordView(
                    title: "전화번호 입력",
                    onSignNextTap: {
                        screen = .registerPhone
                    }
                )
                .environmentObject(authVM)
                
            case .registerPhone:
                PhoneView(
                    onSignNextTap: {
                        screen = .registerInfo
                    }
                )
                .environmentObject(authVM)
                
            case .registerInfo:
                InfoView(
                    title: "이메일 입력",
                    onSignNextTap: {
                        screen = .snapyLogin
                    }
                )
                .environmentObject(authVM)
                
            case .onboarding:
                OnboardingView(onStartTap: {
                    screen = .main
                })

            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: screen)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                screen = .login
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
