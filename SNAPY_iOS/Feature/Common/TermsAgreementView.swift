//
//  TermsAgreementView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/8/26.
//

import SwiftUI

struct TermsAgreementView: View {
    var onBack: () -> Void
    var onAgreed: () -> Void

    @State private var termsAgreed = false
    @State private var privacyAgreed = false

    private var allAgreed: Bool {
        termsAgreed && privacyAgreed
    }

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // 헤더
                SignUpHeader {
                    withAnimation {
                        onBack()
                    }
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("약관에 동의해주세요")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textWhite)

                    Text("서비스 이용을 위해 아래 약관에 동의해주세요.")
                        .font(.system(size: 14))
                        .foregroundColor(.customGray300)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                // 약관 항목들
                VStack(spacing: 0) {
                    // 전체 동의
                    Button {
                        let newValue = !allAgreed
                        termsAgreed = newValue
                        privacyAgreed = newValue
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: allAgreed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(allAgreed ? .MainYellow : .customGray300)

                            Text("전체 동의")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.textWhite)

                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }

                    Divider()
                        .background(Color.customGray500)
                        .padding(.horizontal, 24)

                    // 이용약관
                    termsRow(
                        title: "이용약관 동의 (필수)",
                        isAgreed: $termsAgreed,
                        onView: {
                            print("[Terms] 이용약관 보기 탭")
                        }
                    )

                    // 개인정보 처리방침
                    termsRow(
                        title: "개인정보 처리방침 동의 (필수)",
                        isAgreed: $privacyAgreed,
                        onView: {
                            print("[Terms] 개인정보 처리방침 보기 탭")
                        }
                    )
                }
                .padding(.top, 40)

                Spacer()

                // 동의 버튼
                SignUpButton(
                    title: "동의하고 계속하기",
                    isEnabled: allAgreed
                ) {
                    withAnimation {
                        onAgreed()
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - 약관 행

    @ViewBuilder
    private func termsRow(title: String, isAgreed: Binding<Bool>, onView: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Button {
                isAgreed.wrappedValue.toggle()
            } label: {
                Image(systemName: isAgreed.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isAgreed.wrappedValue ? .MainYellow : .customGray300)
            }

            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.textWhite)

            Spacer()

            Button {
                onView()
            } label: {
                Text("보기")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.customGray300)
                    .underline()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }
}

// MARK: - Preview

#Preview("Terms Agreement") {
    TermsAgreementView(onBack: {}, onAgreed: {})
}
