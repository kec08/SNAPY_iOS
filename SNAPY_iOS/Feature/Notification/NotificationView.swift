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
    @State private var showOlderSection = false

    // 네비게이션
    @State private var navProfileHandle: String? = nil
    @State private var navProfileName: String = ""
    @State private var navProfileImage: String? = nil
    @State private var showFriendRequest = false

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
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Spacer()

                    Text("알림")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.textWhite)

                    Spacer()

                    // 뒤로가기 버튼과 대칭용 여백
                    Color.clear
                        .frame(width: 40, height: 40)
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
                        .font(.system(size: 20))
                        .foregroundColor(Color.customGray300)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            let grouped = groupedNotifications(viewModel.notifications)

                            ForEach(grouped, id: \.title) { section in
                                if section.isOlder {
                                    // 7일 이전 섹션: 더보기 버튼
                                    if !showOlderSection {
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showOlderSection = true
                                            }
                                        } label: {
                                            HStack {
                                                Text("이전 알림 더보기")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(Color.customGray300)
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(Color.customGray300)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                        }
                                    }

                                    if showOlderSection {
                                        HStack {
                                            Text(section.title)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Color.textWhite)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)
                                        .padding(.bottom, 8)

                                        ForEach(section.items) { notification in
                                            notificationRow(notification)
                                        }
                                    }
                                } else {
                                    // 최근 7일 이내 섹션
                                    HStack {
                                        Text(section.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color.textWhite)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                    .padding(.bottom, 8)

                                    ForEach(section.items) { notification in
                                        notificationRow(notification)
                                    }
                                }
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
        .navigationDestination(isPresented: Binding(
            get: { navProfileHandle != nil },
            set: { if !$0 { navProfileHandle = nil } }
        )) {
            if let handle = navProfileHandle {
                FriendProfileView(
                    name: navProfileName,
                    handle: handle,
                    profileImageUrl: navProfileImage
                )
            }
        }
        .navigationDestination(isPresented: $showFriendRequest) {
            FriendRequestView()
        }
        .toolbar(.hidden, for: .navigationBar)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 && abs(value.translation.height) < 100 {
                        dismiss()
                    }
                }
        )
        .task {
            await viewModel.loadNotifications()
            await viewModel.markAllAsRead()
        }
    }

    // MARK: - 알림 Row 헬퍼

    @ViewBuilder
    private func notificationRow(_ notification: NotificationData) -> some View {
        NotificationRow(
            notification: notification,
            message: viewModel.message(for: notification),
            onProfileTap: {
                guard let handle = notification.senderHandle else { return }
                navProfileName = notification.senderUsername ?? ""
                navProfileImage = notification.senderProfileImageUrl
                navProfileHandle = handle
            },
            onContentTap: {
                handleContentTap(notification)
            }
        )
        .onAppear {
            if notification.id == viewModel.notifications.last?.id {
                Task { await viewModel.loadMore() }
            }
        }

        Divider()
            .background(Color.white.opacity(0.06))
    }

    private func handleContentTap(_ notification: NotificationData) {
        switch notification.type {
        case .friendRequest:
            showFriendRequest = true
        case .friendAccepted:
            guard let handle = notification.senderHandle else { return }
            navProfileName = notification.senderUsername ?? ""
            navProfileImage = notification.senderProfileImageUrl
            navProfileHandle = handle
        case .storyLike, .newStory:
            guard let handle = notification.senderHandle else { return }
            navProfileName = notification.senderUsername ?? ""
            navProfileImage = notification.senderProfileImageUrl
            navProfileHandle = handle
        case .feedLike, .feedComment, .albumPublished:
            guard let handle = notification.senderHandle else { return }
            navProfileName = notification.senderUsername ?? ""
            navProfileImage = notification.senderProfileImageUrl
            navProfileHandle = handle
        case .guestbookCreated:
            // 내 프로필(방명록)로 이동
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                NotificationCenter.default.post(name: .switchToProfileTab, object: nil)
            }
        case .albumPhotoUploadReminder:
            // 카메라 열기
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                NotificationCenter.default.post(name: .openCamera, object: nil)
            }
        }
    }

    // MARK: - 날짜별 그룹핑

    private struct NotificationSection {
        let title: String
        let items: [NotificationData]
        var isOlder: Bool = false
    }

    private func groupedNotifications(_ notifications: [NotificationData]) -> [NotificationSection] {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        let weekAgoStart = calendar.date(byAdding: .day, value: -7, to: todayStart)!

        var today: [NotificationData] = []
        var yesterday: [NotificationData] = []
        var recent7Days: [NotificationData] = []
        var older: [NotificationData] = []

        for noti in notifications {
            let date = parseDate(noti.createdAt) ?? .distantPast

            if date >= todayStart {
                today.append(noti)
            } else if date >= yesterdayStart {
                yesterday.append(noti)
            } else if date >= weekAgoStart {
                recent7Days.append(noti)
            } else {
                older.append(noti)
            }
        }

        var sections: [NotificationSection] = []
        if !today.isEmpty { sections.append(NotificationSection(title: "오늘", items: today)) }
        if !yesterday.isEmpty { sections.append(NotificationSection(title: "어제", items: yesterday)) }
        if !recent7Days.isEmpty { sections.append(NotificationSection(title: "최근 7일", items: recent7Days)) }
        if !older.isEmpty { sections.append(NotificationSection(title: "이전", items: older, isOlder: true)) }

        return sections
    }

    private func parseDate(_ dateString: String) -> Date? {
        NotificationDateParser.parse(dateString)
    }
}

// MARK: - 날짜 파싱 유틸

enum NotificationDateParser {
    static func parse(_ dateString: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: dateString) { return date }
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: dateString) { return date }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        // 타임존 없는 경우 KST 우선 처리
        for tz in [TimeZone(identifier: "Asia/Seoul")!, TimeZone(identifier: "UTC")!] {
            for fmt in [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss"
            ] {
                df.dateFormat = fmt
                df.timeZone = tz
                if let date = df.date(from: dateString) { return date }
            }
        }
        return nil
    }
}

// MARK: - 알림 Row

struct NotificationRow: View {
    let notification: NotificationData
    let message: AttributedString
    var onProfileTap: (() -> Void)? = nil
    var onContentTap: (() -> Void)? = nil

    private var isServiceNotification: Bool {
        notification.type == .albumPhotoUploadReminder
    }

    var body: some View {
        HStack(spacing: 12) {
            // 프로필 이미지 / 서비스 알림 아이콘
            if isServiceNotification {
                Image(systemName: notificationIcon)
                    .font(.system(size: 18))
                    .foregroundColor(.MainYellow)
                    .frame(width: 40, height: 40)
                    .background(Color(white: 0.2))
                    .clipShape(Circle())
            } else if let urlString = notification.senderProfileImageUrl,
               let url = URL(string: urlString) {
                Button { onProfileTap?() } label: {
                    KFImage(url)
                        .resizable()
                        .placeholder { Color.customDarkGray }
                        .fade(duration: 0.2)
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                }
            } else {
                Image(systemName: notificationIcon)
                    .font(.system(size: 18))
                    .foregroundColor(.MainYellow)
                    .frame(width: 44, height: 44)
                    .background(Color(white: 0.2))
                    .clipShape(Circle())
            }

            // 메시지 (탭 → 컨텐츠 이동)
            Button {
                onContentTap?()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    if isServiceNotification {
                        Text("앨범에 사진을 올려주세요!")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.textWhite)
                    } else {
                        HStack(spacing: 0) {
                            if let name = notification.senderUsername ?? notification.senderHandle {
                                Button {
                                    onProfileTap?()
                                } label: {
                                    Text(name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color.textWhite)
                                }
                                .buttonStyle(.plain)

                                Text(messageSuffix)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.textWhite)
                            }
                        }
                        .lineLimit(2)
                    }

                    Text(timeAgo(notification.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(Color.customGray300)
                }
            }
            .buttonStyle(.plain)

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

    private var messageSuffix: String {
        switch notification.type {
        case .storyLike:        return "님이 스토리에 좋아요를 눌렀습니다."
        case .feedLike:         return "님이 게시물에 좋아요를 눌렀습니다."
        case .friendRequest:    return "님이 친구 요청을 보냈습니다."
        case .friendAccepted:   return "님이 친구 요청을 수락했습니다."
        case .albumPublished:   return "님의 앨범이 발행되었습니다."
        case .newStory:         return "님이 새 스토리를 올렸습니다."
        case .feedComment:      return "님이 댓글을 남겼습니다."
        case .guestbookCreated: return "님이 방명록을 남겼습니다."
        case .albumPhotoUploadReminder: return ""
        }
    }

    private var notificationIcon: String {
        switch notification.type {
        case .storyLike:        return "heart.fill"
        case .feedLike:         return "heart.fill"
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
        guard let date = NotificationDateParser.parse(dateString) else { return dateString }
        return relativeTime(from: date)
    }

    private func relativeTime(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 0 { return "방금 전" }
        if seconds < 60 { return "방금 전" }
        if seconds < 3600 { return "\(seconds / 60)분 전" }

        let hours = seconds / 3600
        let days = seconds / 86400

        if hours < 24 {
            return "\(hours)시간 전"
        }

        if days < 7 {
            return "\(days)일 전"
        }
        let df = DateFormatter()
        df.dateFormat = "M월 d일"
        df.locale = Locale(identifier: "ko_KR")
        return df.string(from: date)
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}
