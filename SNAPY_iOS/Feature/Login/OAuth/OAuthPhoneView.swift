//
//  OAuthPhoneView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import SwiftUI

struct OAuthPhoneView: View {
    var onNext: () -> Void
    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // 헤더
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

                Text("서비스 이용을 위해\n휴대폰 번호를 등록해주세요")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.textWhite)
                    .lineSpacing(6)
                    .padding(.top, 40)
                    .padding(.horizontal, 24)

                Text("친구 추천 및 연락처 동기화에 사용됩니다")
                    .font(.system(size: 14))
                    .foregroundColor(Color.customGray300)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                VStack(spacing: 0) {
                    SnapyTextField(
                        label: "휴대폰 번호",
                        placeholder: "01012345678",
                        text: $phone,
                        keyboardType: .phonePad
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                }

                Spacer()

                SnapyButton(title: "다음") {
                    register()
                }
                .opacity(isValidPhone ? 1.0 : 0.4)
                .disabled(!isValidPhone || isLoading)
                .padding(.bottom, 24)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private var isValidPhone: Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count == 11
    }

    private func register() {
        let digits = phone.filter { $0.isNumber }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await ProfileService.shared.updatePhone(digits)
                await MainActor.run {
                    isLoading = false
                    onNext()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct OAuthPhoneView_Previews: PreviewProvider {
    static var previews: some View {
        OAuthPhoneView(onNext: {})
    }
}
