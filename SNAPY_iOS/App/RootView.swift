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
                        screen = .onboarding
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
                .environmentObject(authVM)
                
            case .registerPassword:
                PasswordView(
                    onBack: {
                        screen = .registerEmail
                    },
                    onSignNextTap: {
                        screen = .registerPhone
                    }
                )
                .environmentObject(authVM)
                
            case .registerPhone:
                PhoneView(
                    onBack: {
                        screen = .registerPassword
                    },
                    onSignNextTap: {
                        screen = .registerInfo
                    }
                )
                .environmentObject(authVM)
                
            case .registerInfo:
                InfoView(
                    onBack: {
                        screen = .registerPhone
                    },
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
