//
//  PhoneView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/19/26.
//

import SwiftUI

struct PhoneView: View {
    var onSignNextTap: () -> Void
    @EnvironmentObject var authVM: AuthViewModel
    let carriers = ["SKT", "KT", "LG U+", "알뜰폰"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                SignUpHeader {
                    withAnimation {
                        authVM.authFlow = .registerProfile
                    }
                }

                Text("휴대폰 번호를 입력 해주세요")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                VStack(spacing: 28) {
                    // 통신사 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("통신사")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Menu {
                            ForEach(carriers, id: \.self) { carrier in
                                Button(carrier) {
                                    authVM.registerCarrier = carrier
                                }
                            }
                        } label: {
                            HStack {
                                Text(authVM.registerCarrier.isEmpty ? "통신사 선택" : authVM.registerCarrier)
                                    .foregroundColor(
                                        authVM.registerCarrier.isEmpty
                                        ? .customGray300
                                        : .textWhite
                                    )
                                    .font(.system(size: 18))

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                        }

                        Rectangle()
                            .fill(Color.textWhite)
                            .frame(height: 2)
                            .padding(.top, 8)
                    }

                    // 전화번호 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("휴대폰 번호")
                            .font(.system(size: 14))
                            .foregroundColor(.customGray300)

                        HStack(spacing: 12) {

                            TextField("010-0000-0000", text: $authVM.registerPhone)
                                .foregroundColor(.textWhite)
                                .font(.system(size: 18))
                                .keyboardType(.phonePad)
                                .frame(maxWidth: .infinity)

                            Button("인증번호 받기") {
                                // TODO
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textWhite)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                        }

                        Rectangle()
                            .fill(Color.textWhite)
                            .frame(height: 2)
                            .padding(.top, 6)
                    }

                    // 인증번호 입력
                    SnapyTextField(
                        label: "인증번호",
                        placeholder: "인증번호를 입력해주세요",
                        text: $authVM.verificationCode,
                        keyboardType: .numberPad
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                Spacer()

                SignUpButton(
                    title: "확인",
                    isEnabled: authVM.isPhoneValid
                ) {
                    withAnimation {
                        onSignNextTap()
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}

struct PhoneView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneView(onSignNextTap: {})
            .environmentObject(AuthViewModel())
    }
}
