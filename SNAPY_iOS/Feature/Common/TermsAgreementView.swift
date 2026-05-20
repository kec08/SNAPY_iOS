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
    @State private var ageAgreed = false
    @State private var showTermsDetail: TermsDetailType? = nil

    private var allAgreed: Bool {
        termsAgreed && privacyAgreed && ageAgreed
    }

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            if let detailType = showTermsDetail {
                termsDetailPage(type: detailType)
                    .transition(.move(edge: .trailing))
            } else {
                mainContent
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showTermsDetail)
    }

    // MARK: - 메인 약관 동의 화면

    @ViewBuilder
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignUpHeader {
                withAnimation {
                    onBack()
                }
            }
            .padding(.top, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("약관에 동의해주세요")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.textWhite)
                    .padding(.bottom, 6)

                Text("SNAPY 서비스에 오신것을 환영합니다.\n서비스 이용을 위해 아래 약관에 동의해주세요.")
                    .font(.system(size: 14))
                    .foregroundColor(.customGray300)
                    .lineSpacing(6)
                
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
                    ageAgreed = newValue
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
                    onView: { showTermsDetail = .terms }
                )

                // 개인정보 처리방침
                termsRow(
                    title: "개인정보 처리방침 동의 (필수)",
                    isAgreed: $privacyAgreed,
                    onView: { showTermsDetail = .privacy }
                )

                // 만 14세 이상
                termsRow(
                    title: "만 14세 이상입니다 (필수)",
                    isAgreed: $ageAgreed,
                    onView: nil
                )
            }
            .padding(.top, 40)

            Spacer()

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

    // MARK: - 약관 상세 페이지

    @ViewBuilder
    private func termsDetailPage(type: TermsDetailType) -> some View {
        VStack(spacing: 0) {
            // 상단 바
            HStack {
                Button {
                    showTermsDetail = nil
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textWhite)
                }

                Spacer()

                Text(type.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textWhite)

                Spacer()

                // 균형 맞추기용 투명 아이콘
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)

            Divider()
                .background(Color.customGray500)

            ScrollView {
                Text(type.content)
                    .font(.system(size: 14))
                    .foregroundColor(.customGray200)
                    .lineSpacing(6)
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - 약관 행

    @ViewBuilder
    private func termsRow(title: String, isAgreed: Binding<Bool>, onView: (() -> Void)?) -> some View {
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

            if let onView {
                Button {
                    onView()
                } label: {
                    Text("보기")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.customGray300)
                        .underline()
                }
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
