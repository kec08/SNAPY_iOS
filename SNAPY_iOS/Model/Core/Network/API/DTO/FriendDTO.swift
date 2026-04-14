//
//  FriendDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/14/26.
//

import Foundation

// MARK: - 받은 친구 요청

struct ReceivedFriendRequest: Codable, Identifiable {
    let requestId: Int
    let handle: String
    let username: String
    let profileImageUrl: String?

    var id: Int { requestId }
}

typealias ReceivedRequestsResponse = BaseResponse<[ReceivedFriendRequest]>

// MARK: - 친구 요청 상태 조회

enum FriendRequestStatus: String, Codable {
    case none = "NONE"              // 관계 없음
    case pending = "PENDING"        // 내가 보낸 요청 대기 중
    case received = "RECEIVED"      // 상대가 나에게 보낸 요청
    case friend = "FRIEND"          // 이미 친구
}

struct FriendRequestStatusData: Codable {
    let status: String

    var requestStatus: FriendRequestStatus? {
        FriendRequestStatus(rawValue: status)
    }
}

typealias FriendRequestStatusResponse = BaseResponse<FriendRequestStatusData>

// MARK: - 친구 목록

struct FriendData: Codable, Identifiable {
    let handle: String
    let username: String
    let profileImageUrl: String?

    var id: String { handle }
}

typealias FriendListResponse = BaseResponse<[FriendData]>

// MARK: - 연락처 동기화

struct ContactSyncResponseData: Codable {
    let contacts: [ContactUserData]
}

struct ContactUserData: Codable, Identifiable {
    let handle: String
    let username: String
    let profileImageUrl: String?

    var id: String { handle }
}

typealias ContactSyncResponse = BaseResponse<ContactSyncResponseData>

// MARK: - 추천 친구

struct RecommendedFriendData: Codable, Identifiable {
    let handle: String
    let username: String
    let profileImageUrl: String?

    var id: String { handle }
}

typealias RecommendedFriendsResponse = BaseResponse<[RecommendedFriendData]>

// MARK: - 요청 처리 (수락/거절)

enum FriendRequestAction: String, Codable {
    case approve = "APPROVE"
    case reject = "REJECT"
}

struct FriendRequestActionBody: Codable {
    let action: String
}
