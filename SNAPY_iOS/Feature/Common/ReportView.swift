//
//  ReportView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/8/26.
//

import SwiftUI

// MARK: - 신고 타입

enum ReportType: String, CaseIterable {
    case FEED
    case STORY
    case COMMENT
    case USER

    var serverKey: String {
        switch self {
        case .FEED:    return "FEED"
        case .STORY:   return "STORY"
        case .COMMENT: return "FEED" // 댓글은 피드로 신고
        case .USER:    return "PROFILE"
        }
    }
}

// MARK: - 신고 사유

enum ReportReason: String, CaseIterable, Identifiable {
    case spam = "스팸 또는 사기"
    case nudity = "나체 또는 성적 콘텐츠"
    case hateSpeech = "혐오 발언 또는 상징"
    case violence = "폭력 또는 위험한 단체"
    case falseInfo = "거짓 정보"
    case bullying = "따돌림 또는 괴롭힘"
    case intellectual = "지식재산권 침해"
    case other = "기타"

    var id: String { rawValue }

    var serverKey: String {
        switch self {
        case .spam:         return "SPAM_OR_SCAM"
        case .nudity:       return "NUDITY_OR_SEXUAL_CONTENT"
        case .hateSpeech:   return "HATE_SPEECH_OR_SYMBOL"
        case .violence:     return "VIOLENCE_OR_DANGEROUS_ORGANIZATION"
        case .falseInfo:    return "FALSE_INFORMATION"
        case .bullying:     return "BULLYING_OR_HARASSMENT"
        case .intellectual: return "INTELLECTUAL_PROPERTY_INFRINGEMENT"
        case .other:        return "OTHER"
        }
    }
}

// MARK: - ReportView

struct ReportView: View {
    let reportType: ReportType
    let targetId: String
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason? = nil
    @State private var isSubmitted = false

    private var titleText: String {
        switch reportType {
        case .FEED:    return "이 게시물을 신고하는 이유"
        case .STORY:   return "이 스토리를 신고하는 이유"
        case .COMMENT: return "이 댓글을 신고하는 이유"
        case .USER:    return "이 사용자를 신고하는 이유"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    if isSubmitted {
                        // 접수 완료: X 버튼만
                        HStack {
                            Spacer()
                            Button {
                                dismiss()
                                onDismiss?()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.textWhite)
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 20)

                        submittedView
                    } else {
                        // 신고 사유 선택: 타이틀 + 정책 + 리스트
                        HStack {
                            Text(titleText)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.textWhite)
                                .padding(.top, 20)

                            Spacer()

                            Button {
                                dismiss()
                                onDismiss?()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.textWhite)
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                        Text("신고는 익명으로 처리되며, 신고 내용은 상대방에게 전달되지 않습니다. 허위 신고 시 이용이 제한될 수 있습니다.")
                            .font(.system(size: 13))
                            .foregroundColor(.customGray300)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 22)
                            .padding(.top, 8)
                            .padding(.bottom, 16)

                        Divider()
                            .background(Color.customGray500)
                            .padding(.horizontal, 22)
                            .padding(.bottom, 10)

                        reasonListView
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - 사유 리스트

    @ViewBuilder
    private var reasonListView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(ReportReason.allCases) { reason in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedReason = reason
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            submitReport(reason: reason)
                        }
                    } label: {
                        HStack {
                            Text(reason.rawValue)
                                .font(.system(size: 16))
                                .foregroundColor(.textWhite)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.customGray300)
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 20)
                    }
                }
            }
        }

        Spacer()
    }

    // MARK: - 접수 완료 화면

    @ViewBuilder
    private var submittedView: some View {
        Spacer()

        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.MainYellow)

            Text("신고가 접수되었습니다")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textWhite)

            Text("검토 후 적절한 조치를 취하겠습니다.\n소중한 의견 감사합니다.")
                .font(.system(size: 14))
                .foregroundColor(.customGray300)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }

        Spacer()

        Button {
            dismiss()
            onDismiss?()
        } label: {
            Text("확인")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.backgroundBlack)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.MainYellow)
                .cornerRadius(12)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 34)
    }

    // MARK: - 신고 제출

    private func submitReport(reason: ReportReason) {
        Task {
            do {
                if reportType == .USER {
                    try await ReportService.shared.report(
                        targetType: reportType.serverKey,
                        userHandle: targetId,
                        reason: reason.serverKey
                    )
                    print("[Report] 신고 접수 성공 - type: \(reportType.serverKey), handle: \(targetId), reason: \(reason.serverKey)")
                } else {
                    guard let id = Int64(targetId) else {
                        print("[Report] targetId 변환 실패: \(targetId)")
                        return
                    }
                    try await ReportService.shared.report(
                        targetType: reportType.serverKey,
                        targetId: id,
                        reason: reason.serverKey
                    )
                    print("[Report] 신고 접수 성공 - type: \(reportType.serverKey), targetId: \(id), reason: \(reason.serverKey)")
                }
            } catch {
                print("[Report] 신고 접수 실패: \(error)")
            }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSubmitted = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("ReportView - Feed") {
    ReportView(reportType: .FEED, targetId: "123")
}

#Preview("ReportView - User") {
    ReportView(reportType: .USER, targetId: "user_handle")
}
