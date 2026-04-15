//
//  EmailView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/19/26.
//

import SwiftUI

struct EmailView: View {
    var onBack: () -> Void
    var onSignNextTap: () -> Void
    @EnvironmentObject var signUpVM: SiginUpViewModel

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                
                SignUpHeader {
                    withAnimation {
                        onBack()
                    }
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("이메일을 입력해주세요")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.textWhite)
                        .lineSpacing(12)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                VStack(spacing: 8) {
                    SnapyTextField(
                        label: "이메일",
                        placeholder: "이메일을 입력해주세요",
                        text: $signUpVM.registerEmail,
                        keyboardType: .emailAddress
                    )

                    Text("example@email.com 형식으로 입력해주세요")
                        .font(.system(size: 12))
                        .foregroundColor(.customGray300)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let msg = signUpVM.emailValidationMessage {
                        Text(msg)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                if let error = signUpVM.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                }

                Spacer()

                SignUpButton(
                    title: "확인",
                    isEnabled: signUpVM.isEmailValid
                ) {
                    withAnimation {
                        onSignNextTap()
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

struct EmailView_Preview: PreviewProvider {
    static var previews: some View {
        EmailView(onBack: {}, onSignNextTap: {})
            .environmentObject(SiginUpViewModel())
    }
}
