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
    var mutualCount: Int = 0
    var isContact: Bool = false
    var requestState: FriendRequestState = .none
}

enum FriendRequestState {
    case none       // 기본: [추가]
    case requested  // 요청 보냄: [취소]
    case friend     // 이미 친구: [친구]
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
    @Published var pendingRequestCount: Int = 0

    private var searchTask: Task<Void, Never>?

    /// 추천 친구 조회
    func loadRecommendedFriends() async {
        isLoading = true
        // 친구 요청 수 조회
        if let requests = try? await FriendService.shared.getReceivedRequests() {
            pendingRequestCount = requests.count
        }
        do {
            let list = try await FriendService.shared.getRecommendedFriends()
            print("[FriendVM] 추천 친구 조회 성공: \(list.count)명")
            let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""
            let contactHandles = Set(UserDefaults.standard.stringArray(forKey: "contactSyncedHandles") ?? [])

            let filtered = list.filter { $0.handle != myHandle }

            // 먼저 연락처 정보만으로 리스트 표시
            suggestedFriends = filtered.map { friend in
                let isContact = contactHandles.contains(friend.handle)
                return SuggestedFriend(
                    name: friend.username,
                    handle: friend.handle,
                    profileImageUrl: friend.profileImageUrl,
                    mutualText: isContact ? "연락처에 있음" : nil,
                    isContact: isContact
                )
            }
            sortFriends()
            isLoading = false

            // 겹친구 정보를 비동기로 업데이트
            for friend in filtered {
                Task { [weak self] in
                    guard let self else { return }
                    let mutuals = (try? await FriendService.shared.getMutualFriends(handle: friend.handle)) ?? []
                    if !mutuals.isEmpty {
                        if let idx = self.suggestedFriends.firstIndex(where: { $0.handle == friend.handle }) {
                            self.suggestedFriends[idx].mutualCount = mutuals.count
                            if let text = self.buildMutualText(mutuals: mutuals, isContact: false) {
                                self.suggestedFriends[idx].mutualText = text
                            }
                        }
                        self.sortFriends()
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

    /// 정렬: 겹친구 많은 순 > 연락처 > 나머지(등록순 유지)
    private func sortFriends() {
        suggestedFriends.sort { a, b in
            // 1순위: 겹친구 많은 순
            if a.mutualCount != b.mutualCount {
                return a.mutualCount > b.mutualCount
            }
            // 2순위: 연락처에 있는 사람 먼저
            if a.isContact != b.isContact {
                return a.isContact
            }
            // 3순위: 기존 순서 유지 (등록순)
            return false
        }
    }

    /// 우선순위: 겹친구 텍스트 > 연락처에 있음 > nil
    private func buildMutualText(mutuals: [FriendData], isContact: Bool) -> String? {
        if !mutuals.isEmpty {
            let firstName = mutuals[0].username
            if mutuals.count == 1 {
                return "\(firstName)님과 친구입니다"
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
            return searchResults.sorted { a, b in
                if (a.requestState == .friend) != (b.requestState == .friend) {
                    return a.requestState == .friend
                }
                return false
            }
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

                let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""

                // 먼저 연락처 정보만으로 결과 표시 (자기 자신 제외)
                searchResults = results.filter { $0.handle != myHandle }.map { user in
                    let isContact = contactHandles.contains(user.handle)
                    return SuggestedFriend(
                        name: user.username,
                        handle: user.handle,
                        profileImageUrl: user.profileImageUrl,
                        mutualText: isContact ? "연락처에 있음" : nil,
                        isContact: isContact
                    )
                }

                // 친구 요청 상태 + 겹친구 정보 비동기 업데이트
                let handles = results.filter { $0.handle != myHandle }.map { $0.handle }
                for handle in handles {
                    Task { [weak self] in
                        guard let self else { return }

                        // 친구 요청 상태 확인
                        if let status = try? await FriendService.shared.getRequestStatus(handle: handle) {
                            if let idx = self.searchResults.firstIndex(where: { $0.handle == handle }) {
                                if status == .pending {
                                    self.searchResults[idx].requestState = .requested
                                } else if status == .friend {
                                    self.searchResults[idx].requestState = .friend
                                } else if status == .received {
                                    self.searchResults[idx].requestState = .requested
                                }
                            }
                        }

                        // 겹친구 정보
                        let mutuals = (try? await FriendService.shared.getMutualFriends(handle: handle)) ?? []
                        if !mutuals.isEmpty, let text = self.buildMutualText(mutuals: mutuals, isContact: false) {
                            if let idx = self.searchResults.firstIndex(where: { $0.handle == handle }) {
                                self.searchResults[idx].mutualText = text
                                self.searchResults[idx].mutualCount = mutuals.count
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
        // 추천 친구 목록
        if let idx = suggestedFriends.firstIndex(where: { $0.id == friend.id }) {
            suggestedFriends[idx].requestState = .requested
        }
        // 검색 결과
        if let idx = searchResults.firstIndex(where: { $0.id == friend.id }) {
            searchResults[idx].requestState = .requested
        }

        Task {
            do {
                try await FriendService.shared.sendRequest(handle: friend.handle)
            } catch {
                let msg = error.localizedDescription
                if msg.contains("409") || msg.contains("이미") || msg.contains("conflict") {
                    // 이미 보낸 상태이므로 .requested 유지
                } else {
                    if let idx = suggestedFriends.firstIndex(where: { $0.id == friend.id }) {
                        suggestedFriends[idx].requestState = .none
                    }
                    if let idx = searchResults.firstIndex(where: { $0.id == friend.id }) {
                        searchResults[idx].requestState = .none
                    }
                    errorMessage = msg
                }
            }
        }
    }

    /// 취소 버튼 → 서버에 요청 취소
    func cancelRequest(to friend: SuggestedFriend) {
        // 추천 친구 목록에서 찾기
        if let idx = suggestedFriends.firstIndex(where: { $0.id == friend.id }) {
            suggestedFriends[idx].requestState = .none
        }
        // 검색 결과에서도 찾기
        if let idx = searchResults.firstIndex(where: { $0.id == friend.id }) {
            searchResults[idx].requestState = .none
        }

        Task {
            do {
                try await FriendService.shared.cancelRequest(handle: friend.handle)
            } catch {
                // 실패 시 원복
                if let idx = suggestedFriends.firstIndex(where: { $0.id == friend.id }) {
                    suggestedFriends[idx].requestState = .requested
                }
                if let idx = searchResults.firstIndex(where: { $0.id == friend.id }) {
                    searchResults[idx].requestState = .requested
                }
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 프로필에서 돌아왔을 때 요청 상태 갱신
    func refreshRequestStatus(handle: String) {
        Task {
            guard let status = try? await FriendService.shared.getRequestStatus(handle: handle) else { return }
            let newState: FriendRequestState
            switch status {
            case .pending:  newState = .requested
            case .friend:   newState = .friend
            default:        newState = .none
            }

            if let idx = suggestedFriends.firstIndex(where: { $0.handle == handle }) {
                suggestedFriends[idx].requestState = newState
            }
            if let idx = searchResults.firstIndex(where: { $0.handle == handle }) {
                searchResults[idx].requestState = newState
            }
        }
    }

    /// X 버튼 → 목록에서 숨김 (로컬)
    func hideFriend(_ friend: SuggestedFriend) {
        hiddenIds.insert(friend.id)
        searchResults.removeAll { $0.id == friend.id }
    }
}
