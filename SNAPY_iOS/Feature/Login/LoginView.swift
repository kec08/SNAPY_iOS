//
//  LoginView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI
import Combine
import AuthenticationServices

struct LoginView: View {
    var onSnapyTap: () -> Void
    var onRegisterTap: () -> Void
    var onGoogleLoginSuccess: () -> Void = {}
    var onGoogleLoginExistingUser: () -> Void = {}
    var onAppleLoginSuccess: () -> Void = {}
    var onAppleLoginExistingUser: () -> Void = {}
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showErrorAlert = false
    @State private var appleSignInRequest: ASAuthorizationAppleIDRequest?
    @State private var appleSignInCoordinator: AppleSignInCoordinator?

    let images = ["Login_img1", "Login_img2", "Login_img3", "Login_img4", "Login_img5"]

    var body: some View {
        ZStack {
            Color.BackgroundBlack
                .ignoresSafeArea(.all)

            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack(spacing: 12) {
                    Image("Login_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 34)
                    Image("SNAPY_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 28)
                }
                .padding(.top, 34)
                .padding(.horizontal, 24)

                // 타이틀 텍스트
                VStack(alignment: .leading, spacing: 8) {
                    Text("로그인하여 친구들의 SNAPY를 확인해보세요!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textWhite)
                    
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 30)

                // 이미지 캐러셀
                ImageCarousel(images: images, autoScrollInterval: 2.5)
                    .scaleEffect(0.95)

                Spacer()
                    .frame(height: 20)

                HStack(spacing: 8){
                    Text("아직 회원이 아니신가요?")
                        .font(.system(size: 14, weight: .medium))
                    Button {
                        withAnimation {
                                onRegisterTap()
                            }
                    } label: {
                            Text("회원가입")
                                .foregroundColor(Color.mainYellow)
                                .font(.system(size: 14, weight: .semibold))
                    }
                }
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)


                AppleLoginButton(title: "Apple로 계속하기") {
                    let provider = ASAuthorizationAppleIDProvider()
                    let request = provider.createRequest()
                    request.requestedScopes = [.fullName, .email]
                    appleSignInRequest = request
                    appleSignInCoordinator = AppleSignInCoordinator { authorization in
                        Task {
                            await authVM.appleLogin(authorization: authorization)
                            if authVM.isLoggedIn && authVM.isOAuthLogin {
                                do {
                                    _ = try await ProfileService.shared.fetchMyProfile()
                                    onAppleLoginExistingUser()
                                } catch {
                                    onAppleLoginSuccess()
                                }
                            }
                        }
                    } onError: { error in
                        if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                            authVM.errorMessage = "애플 로그인에 실패했습니다."
                        }
                    }
                    let controller = ASAuthorizationController(authorizationRequests: [request])
                    controller.delegate = appleSignInCoordinator
                    controller.performRequests()
                }
                .padding(.bottom, 20)

                GoogleLoginButton(title: "Google로 계속하기") {
                    Task {
                        await authVM.googleLogin()
                        if authVM.isLoggedIn && authVM.isOAuthLogin {
                            // 프로필 조회로 기존 유저인지 확인
                            do {
                                _ = try await ProfileService.shared.fetchMyProfile()
                                // 성공하면 기존 유저 → 바로 메인
                                onGoogleLoginExistingUser()
                            } catch {
                                // 403 등 실패 → 신규 유저 → 설정 플로우
                                onGoogleLoginSuccess()
                            }
                        }
                    }
                }
                .padding(.bottom, 20)

                // 하단 버튼
                SnapyButton(title: "SNAPY로 계속하기") {
                    withAnimation {
                        onSnapyTap()
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .alert("로그인 실패", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel) {
                authVM.errorMessage = nil
            }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
        .onChange(of: authVM.errorMessage) { _, newValue in
            if newValue != nil {
                showErrorAlert = true
            }
        }
    }
}

// MARK: - Apple Sign In Coordinator

class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate {
    let onSuccess: (ASAuthorization) -> Void
    let onError: (Error) -> Void

    init(onSuccess: @escaping (ASAuthorization) -> Void, onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onSuccess(authorization)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onError(error)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onSnapyTap: {}, onRegisterTap: {})
            .environmentObject(AuthViewModel())
    }
}
