//
//  StoryDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/19/26.
//

import Foundation

// MARK: - 스토리 목록 (GET /api/stories)

struct StoryListData: Codable, Identifiable {
    let storyId: Int
    let handle: String
    let username: String
    let profileImageUrl: String?
    let thumbnailUrl: String?
    let createdAt: String?
    let expiresAt: String?

    var id: Int { storyId }
}

// MARK: - 스토리 상세 (GET /api/stories/{storyId})

struct StoryDetailData: Codable {
    let storyId: Int
    let handle: String
    let username: String
    let profileImageUrl: String?
    let photos: [StoryPhotoSet]
    let createdAt: String?
    let expiresAt: String?
}

/// 스토리 안의 사진 한 세트 (전면/후면 + 타입)
struct StoryPhotoSet: Codable, Identifiable {
    let type: String
    let frontImageUrl: String?
    let backImageUrl: String?
    let createdAt: String?

    var id: String { type }

    var albumType: AlbumType? { AlbumType(rawValue: type) }
}

// MARK: - 좋아요 토글 (POST /api/stories/{storyId}/photos/{type}/likes)

struct StoryLikeData: Codable {
    let storyId: Int
    let type: String
    let liked: Bool
}

// MARK: - 좋아요 목록 (GET /api/stories/{storyId}/photos/{type}/likes)

struct StoryLikeUserData: Codable, Identifiable {
    let userId: Int
    let handle: String
    let username: String
    let profileImageUrl: String?
    let likedAt: String?

    var id: Int { userId }
}

// MARK: - typealias

typealias StoryListResponse   = BaseResponse<[StoryListData]>
typealias StoryDetailResponse = BaseResponse<StoryDetailData>
typealias StoryLikeToggleResponse = BaseResponse<StoryLikeData>
typealias StoryLikeListResponse   = BaseResponse<[StoryLikeUserData]>
