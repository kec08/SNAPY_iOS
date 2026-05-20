//
//  FriendProfileViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/18/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class FriendProfileViewModel: ObservableObject {
    let handle: String

    @Published var name: String
    @Published var profileImageUrl: String?
    @Published var bannerImageUrl: String?
    @Published var friendCount: Int = 0
    @Published var postCount: Int = 0
    @Published var streakCount: Int = 0
    @Published var maxStreak: Int = 0
    @Published var mutualFriendsText: String?
    @Published var contactText: String?

    @Published var currentFriend: Bool
    @Published var isFriendRequested = false
    @Published var isLoading = true

    @Published var feedPosts: [FeedPost] = []
    @Published var friendStory: StoryItem? = nil

    init(name: String, handle: String, profileImageUrl: String?,
         bannerImageUrl: String? = nil, isFriend: Bool = false,
         mutualFriendsText: String? = nil, contactText: String? = nil) {
        self.handle = handle
        self.name = name
        self.profileImageUrl = profileImageUrl
        self.bannerImageUrl = bannerImageUrl
        self.currentFriend = isFriend
        self.mutualFriendsText = mutualFriendsText
        self.contactText = contactText
    }

    // MARK: - 전체 로드

    func loadAll() async {
        await loadFriendStory()
        await loadProfile()
        await checkFriendStatus()
        await loadFriendCount()
        await loadMutualFriends()

        let guestbookHandle = handle
        _ = guestbookHandle // guestbook은 View의 guestbookVM에서 처리

        if currentFriend {
            await loadFriendFeed()
        }

        isLoading = false
    }

    // MARK: - 프로필 조회

    func loadProfile() async {
        do {
            let profile = try await ProfileService.shared.fetchUserProfile(handle: handle)
            name = profile.username
            profileImageUrl = profile.profileImageUrl
            bannerImageUrl = profile.backgroundImageUrl
            friendCount = profile.friendCount ?? 0
            streakCount = profile.currentStreak ?? 0
            maxStreak = profile.maxStreak ?? 0
        } catch {
            print("[FriendProfileVM] 프로필 로드 실패: \(error)")
        }
    }

    // MARK: - 친구 여부 확인

    func checkFriendStatus() async {
        if !currentFriend {
            do {
                let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""
                let myFriends = try await FriendService.shared.getFriends(handle: myHandle)
                if myFriends.contains(where: { $0.handle == handle }) {
                    currentFriend = true
                }
            } catch {
                print("[FriendProfileVM] 친구 여부 확인 실패: \(error)")
            }
        }

        if !currentFriend {
            do {
                let status = try await FriendService.shared.getRequestStatus(handle: handle)
                if status == .pending {
                    isFriendRequested = true
                } else if status == .friend {
                    currentFriend = true
                    isFriendRequested = false
                } else {
                    isFriendRequested = false
                }
            } catch {
                isFriendRequested = false
                print("[FriendProfileVM] 요청 상태 확인 실패: \(error)")
            }
        } else {
            isFriendRequested = false
        }
    }

    // MARK: - 친구 수 조회

    func loadFriendCount() async {
        if friendCount == 0 {
            do {
                let friends = try await FriendService.shared.getFriends(handle: handle)
                friendCount = friends.count
            } catch {
                print("[FriendProfileVM] 친구 수 로드 실패: \(error)")
            }
        }
    }

    // MARK: - 겹친구 조회

    func loadMutualFriends() async {
        if mutualFriendsText == nil {
            do {
                let mutuals = try await FriendService.shared.getMutualFriends(handle: handle)
                if !mutuals.isEmpty {
                    let firstName = mutuals[0].username
                    if mutuals.count == 1 {
                        mutualFriendsText = "\(firstName)님과 친구입니다"
                    } else {
                        mutualFriendsText = "\(firstName)님 외 \(mutuals.count - 1)명과 친구입니다"
                    }
                }
            } catch {
                print("[FriendProfileVM] 겹친구 로드 실패: \(error)")
            }

            if mutualFriendsText == nil && contactText == nil {
                let contactHandles = Set(UserDefaults.standard.stringArray(forKey: "contactSyncedHandles") ?? [])
                if contactHandles.contains(handle) {
                    contactText = "연락처에 있음"
                }
            }
        }
    }

    // MARK: - 스토리 로드

    func loadFriendStory() async {
        do {
            let list = try await StoryService.shared.fetchStories()
            let stories = list.filter { $0.handle == handle }
            guard !stories.isEmpty else { friendStory = nil; return }

            var allPhotos: [StoryPhotoSet] = []
            var latest = stories[0]
            for story in stories.sorted(by: { $0.storyId < $1.storyId }) {
                if let detail = try? await StoryService.shared.fetchDetail(storyId: story.storyId) {
                    let photos = detail.photos.map { p -> StoryPhotoSet in
                        var photo = p
                        photo.ownerStoryId = story.storyId
                        return photo
                    }
                    allPhotos.append(contentsOf: photos)
                    if story.storyId > latest.storyId { latest = story }
                }
            }

            guard !allPhotos.isEmpty else { friendStory = nil; return }

            friendStory = StoryItem(
                storyId: latest.storyId,
                profileImage: latest.profileImageUrl ?? "",
                bannerImage: latest.thumbnailUrl ?? "",
                displayName: name,
                username: handle,
                photos: allPhotos,
                createdAt: latest.createdAt,
                isSeen: false
            )
        } catch {
            friendStory = nil
        }
    }

    // MARK: - 피드 로드

    func loadFriendFeed() async {
        let month = Calendar.current.component(.month, from: Date())
        do {
            let albums = try await AlbumService.shared.fetchAlbumsForUser(month: month, handle: handle)
            let sorted = albums.sorted { $0.albumDate > $1.albumDate }

            let posts: [FeedPost] = await withTaskGroup(of: FeedPost?.self) { group in
                for album in sorted {
                    group.addTask {
                        do {
                            let detail = try await AlbumService.shared.fetchAlbumAsDaily(albumId: album.albumId)
                            guard !detail.photos.isEmpty else { return nil }
                            let thumbnail = detail.photos.first?.backImageUrl ?? ""
                            return await FeedPost(
                                id: album.albumId,
                                thumbnailImage: thumbnail,
                                photos: detail.photos,
                                date: Self.formatAlbumDate(album.albumDate),
                                rawDate: album.albumDate,
                                isLiked: detail.liked ?? false,
                                likeCount: detail.likeCount ?? 0
                            )
                        } catch {
                            return nil
                        }
                    }
                }
                var results: [FeedPost] = []
                for await post in group {
                    if let post { results.append(post) }
                }
                return results.sorted { $0.rawDate > $1.rawDate }
            }

            feedPosts = posts
            postCount = posts.count
        } catch {
            print("[FriendProfileVM] 피드 로드 실패: \(error)")
        }
    }

    // MARK: - 새로고침

    func refresh() async {
        await loadProfile()
        if currentFriend {
            await loadFriendFeed()
        }
    }

    // MARK: - 친구 요청

    func sendFriendRequest() {
        isFriendRequested = true
        Task {
            do {
                try await FriendService.shared.sendRequest(handle: handle)
            } catch {
                isFriendRequested = false
            }
        }
    }

    func cancelFriendRequest() {
        isFriendRequested = false
        Task {
            do {
                try await FriendService.shared.cancelRequest(handle: handle)
            } catch {
                isFriendRequested = true
            }
        }
    }

    func toggleFriendRequest() {
        if isFriendRequested {
            cancelFriendRequest()
        } else {
            sendFriendRequest()
        }
    }

    // MARK: - 공유

    func shareProfile() async -> UIImage? {
        async let bannerImg = downloadImage(from: bannerImageUrl)
        async let profileImg = downloadImage(from: profileImageUrl)
        let card = ProfileShareCard(
            bannerImage: await bannerImg,
            profileImage: await profileImg,
            username: name,
            handle: handle,
            postCount: postCount,
            friendCount: friendCount,
            streakCount: streakCount
        )
        return renderShareImage(card)
    }

    // MARK: - 유틸

    static func formatAlbumDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        guard let date = formatter.date(from: dateStr) else { return dateStr }

        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let seconds = Int(-date.timeIntervalSinceNow)
            if seconds < 60 { return "방금 전" }
            if seconds < 3600 { return "\(seconds / 60)분 전" }
            let hours = seconds / 3600
            if hours < 24 { return "\(hours)시간 전" }
        }
        if cal.isDateInYesterday(date) { return "어제" }

        let display = DateFormatter()
        display.dateFormat = "M월 d일"
        display.locale = Locale(identifier: "ko_KR")
        return display.string(from: date)
    }
}
