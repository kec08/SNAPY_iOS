//
//  CommentDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/2/26.
//

import Foundation

// MARK: - 댓글 조회 (GET /api/albums/{albumId}/comments)

struct CommentResponseData: Codable, Identifiable {
    let commentId: Int
    let userId: Int
    let handle: String
    let profileImageUrl: String?
    let type: String                // "EMOJI", "IMAGE", "AUDIO"
    let emojiValue: String?
    let imageUrl: String?
    let audioUrl: String?
    let createdAt: String?

    var id: Int { commentId }
}

// MARK: - 댓글 작성 (POST /api/albums/{albumId}/comments)

struct CommentUploadResponseData: Codable {
    let commentId: Int
    let attachmentId: Int?
    let type: String
    let emojiValue: String?
    let imageUrl: String?
    let audioUrl: String?
    let createdAt: String?
}

// MARK: - typealias

typealias CommentListResponse = BaseResponse<CursorResponse<CommentResponseData>>
typealias CommentUploadResponse = BaseResponse<CommentUploadResponseData>
typealias CommentDeleteResponse = BaseResponse<EmptyData>
