//
//  FeedDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/28/26.
//

import Foundation

// MARK: - 커서 기반 페이지 응답

struct CursorResponse<T: Codable>: Codable {
    let content: [T]
    let nextCursor: Int?
    let hasNext: Bool
}

// MARK: - 피드 아이템 (GET /api/feed)

struct FeedItemData: Codable, Identifiable {
    let albumId: Int
    let albumDate: String
    let photoCount: Int
    let photos: [AlbumPhotoSet]
    let authorName: String
    let authorHandle: String

    var id: Int { albumId }
}

/// 피드/스토리 공용 사진 세트
struct AlbumPhotoSet: Codable {
    let type: String                // "MORNING", "LUNCH", ...
    let frontImageUrl: String?
    let backImageUrl: String?
    let createdAt: String?

    var albumType: AlbumType? { AlbumType(rawValue: type) }
}

// MARK: - typealias

typealias FeedResponse = BaseResponse<CursorResponse<FeedItemData>>
