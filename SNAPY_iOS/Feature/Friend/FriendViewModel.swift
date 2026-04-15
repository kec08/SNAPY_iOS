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
    var mutualText: String?
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
    @Published var searchResults: [SuggestedFriend] = []
    @Published var hiddenIds: Set<UUID> = []
    @Published var errorMessage: String? = nil
    @Published var isLoading = false
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?

    /// 추천 친구 조회
    /// ⚠️ 임시: /api/users?q= (빈 쿼리) 로 전체 유저 조회.
    /// 추후 /api/users/me/recommended-friends 로 교체할 것.
    func loadRecommendedFriends() async {
        isLoading = true
        do {
            let list = try await FriendService.shared.searchUsers(query: "")
            print("[FriendVM] 유저 조회 성공: \(list.count)명")
            let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""
            let contactHandles = Set(UserDefaults.standard.stringArray(forKey: "contactSyncedHandles") ?? [])

            let filtered = list.filter { $0.handle != myHandle }

            // 먼저 연락처 정보만으로 리스트 표시
            suggestedFriends = filtered.map { friend in
                SuggestedFriend(
                    name: friend.username,
                    handle: friend.handle,
                    profileImageUrl: friend.profileImageUrl,
                    mutualText: contactHandles.contains(friend.handle) ? "연락처에 있음" : nil
                )
            }
            isLoading = false

            // 겹친구 정보를 비동기로 업데이트 (우선순위: 겹친구 > 연락처 > nil)
            for friend in filtered {
                Task { [weak self] in
                    guard let self else { return }
                    let mutuals = (try? await FriendService.shared.getMutualFriends(handle: friend.handle)) ?? []
                    if !mutuals.isEmpty, let text = self.buildMutualText(mutuals: mutuals, isContact: false) {
                        print("[FriendVM] 겹친구 \(friend.handle): \(mutuals.count)명")
                        if let idx = self.suggestedFriends.firstIndex(where: { $0.handle == friend.handle }) {
                            self.suggestedFriends[idx].mutualText = text
                        }
                    }
                }
            }
            return
        } catch {
            print("[FriendVM] 유저 조회 실패: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// 우선순위: 겹친구 텍스트 > 연락처에 있음 > nil
    private func buildMutualText(mutuals: [FriendData], isContact: Bool) -> String? {
        if !mutuals.isEmpty {
            let firstName = mutuals[0].username
            if mutuals.count == 1 {
                return "\(firstName)와 친구입니다"
            } else {
                return "\(firstName) 외 \(mutuals.count - 1)명과 친구입니다"
            }
        }
        if isContact {
            return "연락처에 있음"
        }
        return nil
    }

    /// 검색 중이면 서버 결과, 아니면 추천 친구
    var filteredFriends: [SuggestedFriend] {
        if !searchText.isEmpty {
            return searchResults
        }
        return suggestedFriends.filter { !hiddenIds.contains($0.id) }
    }

    /// 검색어 변경 시 서버 검색 (디바운스 0.5초)
    func onSearchTextChanged() {
        searchTask?.cancel()

        guard !searchText.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 디바운스
            guard !Task.isCancelled else { return }

            do {
                let results = try await FriendService.shared.searchUsers(query: searchText)
                guard !Task.isCancelled else { return }
                let contactHandles = Set(UserDefaults.standard.stringArray(forKey: "contactSyncedHandles") ?? [])

                // 먼저 연락처 정보만으로 결과 표시
                searchResults = results.map { user in
                    SuggestedFriend(
                        name: user.username,
                        handle: user.handle,
                        profileImageUrl: user.profileImageUrl,
                        mutualText: contactHandles.contains(user.handle) ? "연락처에 있음" : nil
                    )
                }

                // 겹친구 정보 비동기 업데이트
                for user in results {
                    Task { [weak self] in
                        guard let self, !Task.isCancelled else { return }
                        let mutuals = (try? await FriendService.shared.getMutualFriends(handle: user.handle)) ?? []
                        if !mutuals.isEmpty, let text = self.buildMutualText(mutuals: mutuals, isContact: false) {
                            if let idx = self.searchResults.firstIndex(where: { $0.handle == user.handle }) {
                                self.searchResults[idx].mutualText = text
                            }
                        }
                    }
                }
            } catch {
                if !Task.isCancelled {
                    searchResults = []
                }
            }
            isSearching = false
        }
    }

    /// 추가 버튼 → 서버에 친구 요청 보내기
    func sendRequest(to friend: SuggestedFriend) {
        guard let idx = suggestedFriends.firstIndex(where: { $0.id == friend.id }) else { return }
        suggestedFriends[idx].requestState = .requested

        Task {
            do {
                try await FriendService.shared.sendRequest(handle: friend.handle)
            } catch {
                // 409 (이미 요청/이미 친구) 면 요청됨 상태 유지
                let msg = error.localizedDescription
                if msg.contains("409") || msg.contains("이미") || msg.contains("conflict") {
                    // 이미 보낸 상태이므로 .requested 유지
                } else {
                    suggestedFriends[idx].requestState = .none
                    errorMessage = msg
                }
            }
        }
    }

    /// 취소 버튼 → 서버에 요청 취소
    func cancelRequest(to friend: SuggestedFriend) {
        guard let idx = suggestedFriends.firstIndex(where: { $0.id == friend.id }) else { return }
        suggestedFriends[idx].requestState = .none

        Task {
            do {
                try await FriendService.shared.cancelRequest(handle: friend.handle)
            } catch {
                // 실패 시 원복
                suggestedFriends[idx].requestState = .requested
                errorMessage = error.localizedDescription
            }
        }
    }

    /// X 버튼 → 추천 목록에서 숨김 (로컬)
    func hideFriend(_ friend: SuggestedFriend) {
        hiddenIds.insert(friend.id)
    }
}
