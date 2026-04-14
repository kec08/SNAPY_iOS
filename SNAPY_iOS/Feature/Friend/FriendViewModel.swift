//
//  FriendViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import Foundation
import Combine
import SwiftUI

// 추천 친구 모델
struct SuggestedFriend: Identifiable {
    let id = UUID()
    let name: String
    let handle: String
    let profileImageUrl: String?
    let mutualText: String?     // "김은찬 외 4명과 친구" (nil 이면 표시 안 함)
    var requestState: FriendRequestState = .none
}

enum FriendRequestState {
    case none       // 기본: [추가]
    case requested  // 요청 보냄: [취소]
}

@MainActor
final class FriendViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var suggestedFriends: [SuggestedFriend] = []
    @Published var hiddenIds: Set<UUID> = []

    init() {
        // 임시 목 데이터 5개
        suggestedFriends = [
            SuggestedFriend(name: "김무기", handle: "david_18", profileImageUrl: nil, mutualText: "zhvcx_flii, kimikhnа0816님 외 32명 친구 중 입니다"),
            SuggestedFriend(name: "김은찬", handle: "silver_c.ld", profileImageUrl: nil, mutualText: "zhvcx_flii, kimikhnа0816님 외 32명 친구 중 입니다"),
            SuggestedFriend(name: "홍길동", handle: "hong_gd", profileImageUrl: nil, mutualText: nil),
            SuggestedFriend(name: "권재현", handle: "kwon_jh", profileImageUrl: nil, mutualText: nil),
            SuggestedFriend(name: "문종은", handle: "moon_je", profileImageUrl: nil, mutualText: nil),
        ]
    }

    /// 검색 필터 + 숨김 제외
    var filteredFriends: [SuggestedFriend] {
        let visible = suggestedFriends.filter { !hiddenIds.contains($0.id) }
        if searchText.isEmpty { return visible }
        let query = searchText.lowercased()
        return visible.filter {
            $0.name.lowercased().contains(query) || $0.handle.lowercased().contains(query)
        }
    }

    /// 추가 버튼 → 요청 보냄
    func sendRequest(to friend: SuggestedFriend) {
        guard let idx = suggestedFriends.firstIndex(where: { $0.id == friend.id }) else { return }
        suggestedFriends[idx].requestState = .requested
    }

    /// 취소 버튼 → 요청 취소
    func cancelRequest(to friend: SuggestedFriend) {
        guard let idx = suggestedFriends.firstIndex(where: { $0.id == friend.id }) else { return }
        suggestedFriends[idx].requestState = .none
    }

    /// X 버튼 → 추천 목록에서 숨김 (로컬)
    func hideFriend(_ friend: SuggestedFriend) {
        hiddenIds.insert(friend.id)
    }
}
