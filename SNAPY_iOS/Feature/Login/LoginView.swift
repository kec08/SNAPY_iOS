//
//  LoginView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI
import Combine

struct LoginView: View {
    var onSnapyTap: () -> Void
    var onRegisterTap: () -> Void
    @EnvironmentObject var authVM: AuthViewModel

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
                    Image("Login_TextLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 28)
                }
                .padding(.top, 34)
                .padding(.horizontal, 24)

                // 타이틀 텍스트
                VStack(alignment: .leading, spacing: 8) {
                    Text("로그인하여 친구들의 SNAPY를\n확인해보세요!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textWhite)
                        .lineSpacing(8)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 40)

                // 이미지 캐러셀
                ImageCarousel(images: images, autoScrollInterval: 2.5)

                Spacer()
                    .frame(height: 40)

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
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)


                AppleLoginButton(title: "Apple로 계속하기") {
                    withAnimation {
                        print("Apple로 계속하기 클릭")
                    }
                }
                .padding(.bottom, 24)

                // 하단 버튼
                SnapyButton(title: "SNAPY로 계속하기") {
                    withAnimation {
                        onSnapyTap()
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onSnapyTap: {}, onRegisterTap: {})
            .environmentObject(AuthViewModel())
    }
}
