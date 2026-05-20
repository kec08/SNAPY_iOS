//
//  BlockDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/20/26.
//

import Foundation

struct BlockedUserData: Codable, Identifiable, Hashable {
    let handle: String
    let username: String
    let profileImageUrl: String?
    let blockedAt: String?

    var id: String { handle }
}

typealias BlockedUsersResponse = BaseResponse<[BlockedUserData]>
