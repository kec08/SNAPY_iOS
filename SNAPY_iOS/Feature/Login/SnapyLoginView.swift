//
//  SnapyLoginView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct SnapyLoginView: View {
    var onLoginTap: () -> Void
    var onRegisterTap: () -> Void
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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

                VStack(alignment: .leading, spacing: 8) {
                    Text("로그인하여 친구들의 SNAPY를\n확인해보세요!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textWhite)
                        .lineSpacing(12)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                VStack(spacing: 32) {
                    SnapyTextField(
                        label: "이메일",
                        placeholder: "이메일을 입력해주세요",
                        text: $authVM.loginEmail,
                        keyboardType: .emailAddress
                    )

                    SnapyTextField(
                        label: "비밀번호",
                        placeholder: "비밀번호를 입력해주세요",
                        text: $authVM.loginPassword,
                        isSecure: true
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                
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
                .padding(.top, 28)
                .frame(maxWidth: .infinity)
                

                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // 로그인 버튼
                SnapyButton(title: "SNAPY로 로그인") {
                    withAnimation {
                        onLoginTap()
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

struct SnapyLoginView_Preview: PreviewProvider {
    static var previews: some View {
        SnapyLoginView(onLoginTap: {}, onRegisterTap: {})
            .environmentObject(AuthViewModel())
    }
}
