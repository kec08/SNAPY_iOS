//
//  NotificationViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class NotificationViewModel: ObservableObject {
    @Published var notifications: [NotificationData] = []
    @Published var unreadCount: Int64 = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = NotificationService.shared
    private var currentPage = 0
    private var hasNext = true

    // MARK: - 알림 목록 로드

    func loadNotifications() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        currentPage = 0

        do {
            let data = try await service.getNotifications(page: 0, size: 20)
            notifications = data.items
            hasNext = data.hasNext
            currentPage = 0
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - 추가 로드 (페이징)

    func loadMore() async {
        guard !isLoading, hasNext else { return }
        isLoading = true

        let nextPage = currentPage + 1

        do {
            let data = try await service.getNotifications(page: nextPage, size: 20)
            notifications.append(contentsOf: data.items)
            hasNext = data.hasNext
            currentPage = nextPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - 읽지 않은 알림 수

    func fetchUnreadCount() async {
        do {
            unreadCount = try await service.getUnreadCount()
        } catch {
            print("[Notification] 읽지 않은 알림 수 조회 실패: \(error)")
        }
    }

    // MARK: - 알림 읽음 처리

    func markAsRead(_ notification: NotificationData) async {
        guard !notification.read else { return }

        do {
            try await service.markAsRead(id: notification.id)
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                // read 상태 업데이트를 위해 새 객체 생성
                let updated = NotificationData(
                    id: notification.id,
                    senderId: notification.senderId,
                    senderHandle: notification.senderHandle,
                    senderUsername: notification.senderUsername,
                    senderProfileImageUrl: notification.senderProfileImageUrl,
                    type: notification.type,
                    referenceId: notification.referenceId,
                    referenceType: notification.referenceType,
                    read: true,
                    createdAt: notification.createdAt
                )
                notifications[index] = updated
            }
            if unreadCount > 0 { unreadCount -= 1 }
        } catch {
            print("[Notification] 읽음 처리 실패: \(error)")
        }
    }

    // MARK: - 전체 읽음 처리

    func markAllAsRead() async {
        do {
            try await service.markAllAsRead()
            notifications = notifications.map { noti in
                NotificationData(
                    id: noti.id,
                    senderId: noti.senderId,
                    senderHandle: noti.senderHandle,
                    senderUsername: noti.senderUsername,
                    senderProfileImageUrl: noti.senderProfileImageUrl,
                    type: noti.type,
                    referenceId: noti.referenceId,
                    referenceType: noti.referenceType,
                    read: true,
                    createdAt: noti.createdAt
                )
            }
            unreadCount = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - 알림 타입별 메시지

    func message(for notification: NotificationData) -> AttributedString {
        let name = notification.senderUsername ?? notification.senderHandle ?? "알 수 없음"
        let suffix: String
        switch notification.type {
        case .storyLike:
            suffix = "님이 스토리에 좋아요를 눌렀습니다."
        case .friendRequest:
            suffix = "님이 친구 요청을 보냈습니다."
        case .friendAccepted:
            suffix = "님이 친구 요청을 수락했습니다."
        case .albumPublished:
            suffix = "님의 앨범이 발행되었습니다."
        case .newStory:
            suffix = "님이 새 스토리를 올렸습니다."
        case .feedComment:
            suffix = "님이 댓글을 남겼습니다."
        case .guestbookCreated:
            suffix = "님이 방명록을 남겼습니다."
        case .albumPhotoUploadReminder:
            var text = AttributedString("앨범에 사진을 올려주세요!")
            text.font = .system(size: 14, weight: .regular)
            return text
        }

        var boldName = AttributedString(name)
        boldName.font = .system(size: 14, weight: .bold)

        var rest = AttributedString(suffix)
        rest.font = .system(size: 14, weight: .regular)

        return boldName + rest
    }
}
