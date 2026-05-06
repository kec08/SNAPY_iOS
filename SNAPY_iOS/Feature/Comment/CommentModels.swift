//
//  CommentModels.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/22/26.
//

import Foundation

// MARK: - 댓글 타입

enum CommentType {
    case image(url: String)
    case voice(url: String, duration: TimeInterval)
    case emoji(String)
}

// MARK: - 댓글 모델

struct Comment: Identifiable {
    let id: Int               // 서버 commentId
    let userId: Int
    let profileImageUrl: String?
    let handle: String
    let type: CommentType
    let createdAt: Date

    /// 서버 CommentResponseData → Comment 변환
    init(from data: CommentResponseData) {
        self.id = data.commentId
        self.userId = data.userId
        self.profileImageUrl = data.profileImageUrl
        self.handle = data.handle

        switch data.type {
        case "IMAGE":
            self.type = .image(url: data.imageUrl ?? "")
        case "AUDIO":
            self.type = .voice(url: data.audioUrl ?? "", duration: 0)
        default:
            self.type = .emoji(data.emojiValue ?? "")
        }

        if let dateStr = data.createdAt {
            self.createdAt = Self.parseDate(dateStr) ?? Date()
        } else {
            self.createdAt = Date()
        }
    }

    /// 로컬 생성용 (낙관적 추가)
    init(id: Int = 0, userId: Int = 0, profileImageUrl: String?, handle: String, type: CommentType, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.profileImageUrl = profileImageUrl
        self.handle = handle
        self.type = type
        self.createdAt = createdAt
    }

    private static func parseDate(_ str: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: str) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: str) { return d }

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss"] {
            fmt.dateFormat = format
            if let d = fmt.date(from: str) { return d }
        }
        return nil
    }
}
