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
    let id = UUID()
    let profileImageUrl: String?
    let handle: String
    let type: CommentType
    let createdAt: Date
}
