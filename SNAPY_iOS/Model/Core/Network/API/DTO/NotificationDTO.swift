//
//  NotificationDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import Foundation

// MARK: - 알림 타입

enum NotificationType: String, Codable {
    case albumPhotoUploadReminder = "ALBUM_PHOTO_UPLOAD_REMINDER"
    case storyLike = "STORY_LIKE"
    case feedLike = "FEED_LIKE"
    case friendRequest = "FRIEND_REQUEST"
    case friendAccepted = "FRIEND_ACCEPTED"
    case albumPublished = "ALBUM_PUBLISHED"
    case newStory = "NEW_STORY"
    case feedComment = "FEED_COMMENT"
    case guestbookCreated = "GUESTBOOK_CREATED"
}

// MARK: - 알림 응답

struct NotificationData: Codable, Identifiable {
    let id: Int64
    let senderId: Int64?
    let senderHandle: String?
    let senderUsername: String?
    let senderProfileImageUrl: String?
    let type: NotificationType
    let referenceId: Int64?
    let referenceType: String?
    let read: Bool
    let createdAt: String
}

struct NotificationPageData: Codable {
    let items: [NotificationData]
    let page: Int
    let size: Int
    let hasNext: Bool
}

typealias NotificationPageResponse = BaseResponse<NotificationPageData>

// MARK: - 읽지 않은 알림 수

struct UnreadCountData: Codable {
    let count: Int64
}

typealias UnreadCountResponse = BaseResponse<UnreadCountData>
