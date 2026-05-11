//
//  OAuthInfoView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import SwiftUI

struct OAuthInfoView: View {
    var onNext: () -> Void
    @EnvironmentObject var authVM: AuthViewModel

    @State private var handle = ""
    @State private var username = ""
    @State private var handleValidation: String?
    @State private var isSaving = false
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

                Text("사용자 정보를 입력해주세요")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.textWhite)
                    .padding(.top, 32)
                    .padding(.horizontal, 24)

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        SnapyTextField(
                            label: "사용자 ID",
                            placeholder: "ID를 입력해주세요",
                            text: $handle
                        )

                        Text("영문, 숫자, 밑줄(_), 마침표(.)만 사용 가능합니다")
                            .font(.system(size: 12))
                            .foregroundColor(.customGray300)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let msg = handleValidation {
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
                            text: $username
                        )

                        Text("다른 사용자에게 표시되는 이름입니다")
                            .font(.system(size: 12))
                            .foregroundColor(.customGray300)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                Spacer()

                SnapyButton(title: isSaving ? "저장 중..." : "다음", isEnabled: isValid && !isSaving) {
                    Task { await saveAndNext() }
                }
                .padding(.bottom, 24)
            }
        }
        .alert("오류", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            handle = authVM.oauthDefaultHandle
            username = authVM.oauthDefaultName
        }
        .onChange(of: handle) { _, newValue in
            validateHandle(newValue)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private var isValid: Bool {
        !handle.isEmpty && !username.isEmpty && handleValidation == nil
    }

    private func saveAndNext() async {
        isSaving = true
        errorMessage = nil

        do {
            // 핸들 중복 확인
            let available = try await ProfileService.shared.checkHandle(handle)
            if !available {
                errorMessage = "이미 사용 중인 사용자 ID입니다."
                isSaving = false
                return
            }

            // 핸들 + 이름 저장
            try await ProfileService.shared.updateHandle(handle)
            try await ProfileService.shared.updateUsername(username)

            await MainActor.run {
                isSaving = false
                withAnimation { onNext() }
            }
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }

    private func validateHandle(_ value: String) {
        if value.isEmpty {
            handleValidation = nil
            return
        }
        if value.count < 5 {
            handleValidation = "5자 이상 입력해주세요"
            return
        }
        if value.count > 24 {
            handleValidation = "24자 이하로 입력해주세요"
            return
        }
        if value.contains(" ") {
            handleValidation = "공백은 사용할 수 없습니다"
            return
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_."))
        if !value.unicodeScalars.allSatisfy({ allowed.contains($0) }) {
            handleValidation = "영문, 숫자, 밑줄(_), 마침표(.)만 사용 가능합니다"
            return
        }
        handleValidation = nil
    }
}

struct OAuthInfoView_Previews: PreviewProvider {
    static var previews: some View {
        OAuthInfoView(onNext: {})
            .environmentObject(AuthViewModel())
    }
}
