//
//  NotificationView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import SwiftUI
import Kingfisher

struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // 헤더
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.textWhite)
                    }

                    Spacer()

                    Text("알림")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.textWhite)

                    Spacer()

                    // 전체 읽음
                    Button {
                        Task { await viewModel.markAllAsRead() }
                    } label: {
                        Text("모두 읽음")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.customGray300)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                Divider()
                    .background(Color.white.opacity(0.1))

                // 알림 목록
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(Color.textWhite)
                    Spacer()
                } else if viewModel.notifications.isEmpty {
                    Spacer()
                    Text("알림이 없습니다")
                        .font(.system(size: 15))
                        .foregroundColor(Color.customGray300)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.notifications) { notification in
                                NotificationRow(
                                    notification: notification,
                                    message: viewModel.message(for: notification)
                                )
                                .onTapGesture {
                                    Task { await viewModel.markAsRead(notification) }
                                }
                                .onAppear {
                                    if notification.id == viewModel.notifications.last?.id {
                                        Task { await viewModel.loadMore() }
                                    }
                                }

                                Divider()
                                    .background(Color.white.opacity(0.06))
                            }

                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(Color.textWhite)
                                    .padding(.vertical, 20)
                            }
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadNotifications()
        }
    }
}

// MARK: - 알림 Row

struct NotificationRow: View {
    let notification: NotificationData
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            // 프로필 이미지
            if let urlString = notification.senderProfileImageUrl,
               let url = URL(string: urlString) {
                KFImage(url)
                    .resizable()
                    .placeholder { Color.customDarkGray }
                    .fade(duration: 0.2)
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Image(systemName: notificationIcon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.textWhite)
                    .frame(width: 44, height: 44)
                    .background(Color.customDarkGray)
                    .clipShape(Circle())
            }

            // 메시지
            VStack(alignment: .leading, spacing: 4) {
                Text(message)
                    .font(.system(size: 14, weight: notification.read ? .regular : .semibold))
                    .foregroundColor(Color.textWhite)
                    .lineLimit(2)

                Text(timeAgo(notification.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(Color.customGray300)
            }

            Spacer()

            // 읽지 않은 표시
            if !notification.read {
                Circle()
                    .fill(Color.mainYellow)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(notification.read ? Color.clear : Color.white.opacity(0.03))
    }

    private var notificationIcon: String {
        switch notification.type {
        case .storyLike:        return "heart.fill"
        case .friendRequest:    return "person.badge.plus"
        case .friendAccepted:   return "person.2.fill"
        case .albumPublished:   return "book.fill"
        case .newStory:         return "camera.fill"
        case .feedComment:      return "bubble.left.fill"
        case .guestbookCreated: return "text.book.closed.fill"
        case .albumPhotoUploadReminder: return "bell.fill"
        }
    }

    private func timeAgo(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: dateString) else {
            // fractionalSeconds 없이 재시도
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateString) else { return dateString }
            return relativeTime(from: date)
        }
        return relativeTime(from: date)
    }

    private func relativeTime(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "방금 전" }
        if seconds < 3600 { return "\(seconds / 60)분 전" }
        if seconds < 86400 { return "\(seconds / 3600)시간 전" }
        if seconds < 604800 { return "\(seconds / 86400)일 전" }
        let df = DateFormatter()
        df.dateFormat = "M월 d일"
        return df.string(from: date)
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
