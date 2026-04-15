//
//  InfoView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/19/26.
//

import SwiftUI

struct InfoView: View {
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
                    Text("사용자 정보 입력해주세요")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.textWhite)
                        .lineSpacing(12)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        SnapyTextField(
                            label: "사용자 ID",
                            placeholder: "ID를 입력해주세요",
                            text: $signUpVM.registerUserID
                        )

                        Text("영문, 숫자, 밑줄(_), 마침표(.)만 사용 가능합니다")
                            .font(.system(size: 12))
                            .foregroundColor(.customGray300)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let msg = signUpVM.userIDValidationMessage {
                            Text(msg)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    VStack(spacing: 8) {
                        SnapyTextField(
                            label: "이름",
                            placeholder: "이름을 입력해주세요",
                            text: $signUpVM.registerUsername
                        )

                        Text("다른 사용자에게 표시되는 이름입니다")
                            .font(.system(size: 12))
                            .foregroundColor(.customGray300)
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

                // 로그인 버튼
                SignUpButton(
                    title: "확인",
                    isEnabled: !signUpVM.registerUserID.isEmpty &&
                                !signUpVM.registerUsername.isEmpty
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

struct InfoView_Preview: PreviewProvider {
    static var previews: some View {
        InfoView(onBack: {}, onSignNextTap: {})
            .environmentObject(SiginUpViewModel())
    }
}
