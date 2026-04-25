//
//  GuestbookDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/23/26.
//

import Foundation

// MARK: - 방명록 조회 응답

struct GuestbookResponseData: Codable, Identifiable {
    let author: GuestbookAuthor
    let imageUrl: String?
    let createdAt: String?

    var id: String { (author.handle ?? "") + (createdAt ?? UUID().uuidString) }
}

struct GuestbookAuthor: Codable {
    let handle: String?
    let profileImageUrl: String?
}

// MARK: - 방명록 작성 응답

struct GuestbookCreateResponseData: Codable {
    let owner: GuestbookAuthor
    let author: GuestbookAuthor
    let imageUrl: String?
    let createdAt: String?
}

// MARK: - typealias

typealias GuestbookListResponse = BaseResponse<[GuestbookResponseData]>
typealias GuestbookCreateResponse = BaseResponse<GuestbookCreateResponseData>
