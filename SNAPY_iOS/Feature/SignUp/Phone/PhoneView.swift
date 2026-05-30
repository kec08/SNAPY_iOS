//
//  PhoneView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/19/26.
//

import SwiftUI

struct PhoneView: View {
    var onBack: () -> Void
    var onSignNextTap: () -> Void
    @EnvironmentObject var signUpVM: SiginUpViewModel
    @State private var codeSent = false
    @State private var isSending = false
    @State private var sendError: String?

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

                Text("휴대폰 번호를 입력 해주세요")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                VStack(spacing: 28) {
                    // 전화번호 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("휴대폰 번호")
                            .font(.system(size: 14))
                            .foregroundColor(.customGray300)

                        HStack(spacing: 12) {

                            TextField("010-0000-0000", text: Binding(
                                get: { signUpVM.formattedPhone },
                                set: { newValue in
                                    // 숫자와 하이픈만 허용, 숫자만 저장
                                    let digits = newValue.filter { $0.isNumber }
                                    signUpVM.registerPhone = String(digits.prefix(11))
                                }
                            ))
                                .foregroundColor(.textWhite)
                                .font(.system(size: 18))
                                .keyboardType(.phonePad)
                                .frame(maxWidth: .infinity)

                            Button(codeSent ? "재발송" : "인증번호 받기") {
                                requestCode()
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(signUpVM.registerPhone.count == 11 ? .textWhite : .customGray300)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(signUpVM.registerPhone.count == 11 ? Color.gray : Color.customGray500, lineWidth: 1)
                            )
                            .disabled(signUpVM.registerPhone.count != 11 || isSending)
                        }

                        Rectangle()
                            .fill(Color.textWhite)
                            .frame(height: 2)
                            .padding(.top, 6)

                        Text("휴대폰 번호 11자리를 입력해주세요")
                            .font(.system(size: 12))
                            .foregroundColor(.customGray300)

                        if let msg = signUpVM.phoneValidationMessage {
                            Text(msg)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }

                        if codeSent {
                            Text("인증번호가 발송되었습니다.")
                                .font(.system(size: 12))
                                .foregroundColor(.MainYellow)
                        }

                        if let error = sendError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }

                    // 인증번호 입력
                    SnapyTextField(
                        label: "인증번호",
                        placeholder: "인증번호를 입력해주세요",
                        text: $signUpVM.verificationCode,
                        keyboardType: .numberPad
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                Spacer()

                SignUpButton(
                    title: "확인",
                    isEnabled: signUpVM.isPhoneValid
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

    private func requestCode() {
        let digits = signUpVM.registerPhone
        guard digits.count == 11 else { return }
        isSending = true
        sendError = nil

        Task {
            do {
                try await ProfileService.shared.requestPhoneCode(digits)
                await MainActor.run {
                    codeSent = true
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    sendError = error.localizedDescription
                    isSending = false
                }
            }
        }
    }
}

struct PhoneView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneView(onBack: {}, onSignNextTap: {})
            .environmentObject(SiginUpViewModel())
    }
}
