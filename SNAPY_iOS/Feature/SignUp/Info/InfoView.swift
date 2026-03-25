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

                VStack(spacing: 32) {
                    SnapyTextField(
                        label: "사용자 ID",
                        placeholder: "ID를 입력해주세요",
                        text: $signUpVM.registerUserID
                    )
                    
                    SnapyTextField(
                        label: "이름",
                        placeholder: "이름을 입력해주세요",
                        text: $signUpVM.registerUsername
                    )
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
