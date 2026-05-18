//
//  HomeViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 홈 피드 모델

/// 피드에 표시할 사진 한 장
struct FeedPhoto: Identifiable {
    let id = UUID()
    let frontImageUrl: String?   // 전면 카메라 (PIP)
    let backImageUrl: String?    // 후면 카메라 (배경)
    let assetName: String?       // 로컬 에셋 이름 (mock용)
}

struct HomeFeedPost: Identifiable {
    let id = UUID()
    let albumId: Int                 // 서버 앨범 ID (댓글 조회에 사용)
    let profileImage: String        // asset 이름 URL (http로 시작하면 URL로 인식)
    let displayName: String
    let handle: String
    let date: String
    let photos: [FeedPhoto]         // front+back 쌍 배열
    var isLiked: Bool = false
    var likeCount: Int = 0
    var commentCount: Int = 0
    var hasStory: Bool = false       // 스토리 올렸는지 여부
    var isStorySeen: Bool = true     // 스토리를 이미 봤는지
}

extension String {
    /// 이미지 문자열이 URL인지 (http/https로 시작) — 피드/스토리에서 asset vs URL 분기에 사용
    var isImageURL: Bool { hasPrefix("http") }
}

struct StoryItem: Identifiable {
    let id = UUID()
    let storyId: Int           // 대표 스토리 ID (가장 최신)
    let storyIds: [Int]        // 이 유저의 모든 스토리 ID
    let profileImage: String
    let bannerImage: String
    let displayName: String
    let username: String       // handle
    let photos: [StoryPhotoSet]  // 서버의 사진 세트 (front/back + type)
    let createdAt: String?     // ISO8601 서버 시각
    let isSeen: Bool
    let unseenStartIndex: Int  // 새로 올린 사진 시작 인덱스

    init(storyId: Int, profileImage: String, bannerImage: String,
         displayName: String, username: String, photos: [StoryPhotoSet],
         createdAt: String?, isSeen: Bool) {
        self.storyId = storyId
        self.storyIds = [storyId]
        self.profileImage = profileImage
        self.bannerImage = bannerImage
        self.displayName = displayName
        self.username = username
        self.photos = photos
        self.createdAt = createdAt
        self.isSeen = isSeen
        self.unseenStartIndex = 0
    }

    init(storyId: Int, storyIds: [Int], profileImage: String, bannerImage: String,
         displayName: String, username: String, photos: [StoryPhotoSet],
         createdAt: String?, isSeen: Bool, unseenStartIndex: Int = 0) {
        self.storyId = storyId
        self.storyIds = storyIds
        self.profileImage = profileImage
        self.bannerImage = bannerImage
        self.displayName = displayName
        self.username = username
        self.photos = photos
        self.createdAt = createdAt
        self.isSeen = isSeen
        self.unseenStartIndex = unseenStartIndex
    }

    /// 하위 호환: 기존 images 접근이 필요한 곳에서 backImageUrl 배열로 변환
    var images: [String] {
        photos.compactMap { $0.backImageUrl }
    }

    /// createdAt → "40분 전", "3시간 전" 등 상대 시간 텍스트
    var relativeTimeText: String {
        guard let createdAt, !createdAt.isEmpty else { return "" }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: createdAt)
                ?? ISO8601DateFormatter().date(from: createdAt)
                ?? Self.parseFlexible(createdAt) else {
            return ""
        }

        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "방금 전" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)분 전" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)시간 전" }
        let days = hours / 24
        return "\(days)일 전"
    }

    private static func parseFlexible(_ str: String) -> Date? {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "Asia/Seoul")
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss"] {
            fmt.dateFormat = format
            if let d = fmt.date(from: str) { return d }
        }
        return nil
    }
}

// MARK: - 스토리 Seen 상태 (전역)

enum SeenStoryStore {
    static var ids: Set<Int> {
        get { Set((UserDefaults.standard.array(forKey: "seenStoryIds") as? [Int]) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "seenStoryIds") }
    }

    /// 읽은 시간 (storyId → timestamp)
    private static var seenTimes: [Int: TimeInterval] {
        get { (UserDefaults.standard.dictionary(forKey: "seenStoryTimes") as? [String: TimeInterval])?.reduce(into: [:]) { $0[Int($1.key) ?? 0] = $1.value } ?? [:] }
        set { UserDefaults.standard.set(newValue.reduce(into: [String: TimeInterval]()) { $0["\($1.key)"] = $1.value }, forKey: "seenStoryTimes") }
    }

    static func isSeen(_ storyId: Int) -> Bool { ids.contains(storyId) }

    /// 읽은 시간 반환 (없으면 0)
    static func seenTime(_ storyId: Int) -> TimeInterval {
        seenTimes[storyId] ?? 0
    }

    static func markSeen(_ storyId: Int) {
        var current = ids
        current.insert(storyId)
        ids = current
        var times = seenTimes
        if times[storyId] == nil {
            times[storyId] = Date().timeIntervalSince1970
        }
        seenTimes = times
    }

    static func markSeen(_ storyIds: [Int]) {
        var current = ids
        var times = seenTimes
        let now = Date().timeIntervalSince1970
        storyIds.forEach {
            current.insert($0)
            if times[$0] == nil { times[$0] = now }
        }
        ids = current
        seenTimes = times
    }
}

// MARK: - ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var stories: [StoryItem] = []
    @Published var feedPosts: [HomeFeedPost] = []
    @Published var isLoadingStories: Bool = false
    @Published var isLoadingFeed: Bool = false

    /// 커서 기반 페이지네이션
    private var nextCursor: Int? = nil
    private(set) var hasMoreFeed: Bool = true

    /// 이미 본 스토리 ID (전역 SeenStoryStore 사용)
    private var seenStoryIds: Set<Int> {
        get { SeenStoryStore.ids }
        set { SeenStoryStore.ids = newValue }
    }

    init() {}

    // MARK: - 스토리 목록 로드 (서버 API)

    /// GET /api/stories → 목록 조회 후, 각 스토리 상세(photos)를 병렬 로드
    func loadStories() async {
        isLoadingStories = true
        defer { isLoadingStories = false }

        do {
            let list = try await StoryService.shared.fetchStories()
            print("[HomeViewModel] 스토리 목록 \(list.count)개 수신")

            // 병렬로 상세 조회 (withTaskGroup)
            let items: [StoryItem] = await withTaskGroup(of: StoryItem?.self) { group in
                for story in list {
                    group.addTask {
                        do {
                            let detail = try await StoryService.shared.fetchDetail(storyId: story.storyId)
                            // 각 사진에 원래 storyId 세팅
                            let photos = detail.photos.map { photo -> StoryPhotoSet in
                                var p = photo
                                p.ownerStoryId = story.storyId
                                return p
                            }
                            let bannerImg = photos.first?.backImageUrl ?? story.thumbnailUrl ?? ""
                            return await StoryItem(
                                storyId: story.storyId,
                                profileImage: story.profileImageUrl ?? "",
                                bannerImage: bannerImg,
                                displayName: detail.username,
                                username: story.handle,
                                photos: photos,
                                createdAt: detail.createdAt ?? story.createdAt,
                                isSeen: self.seenStoryIds.contains(story.storyId)
                            )
                        } catch {
                            print("[HomeViewModel] 스토리 상세 실패 (id=\(story.storyId)): \(error)")
                            return nil
                        }
                    }
                }
                var results: [StoryItem] = []
                for await item in group {
                    if let item { results.append(item) }
                }
                return results
            }

            // 같은 유저의 스토리를 하나로 합치기
            var grouped: [String: [StoryItem]] = [:]
            for item in items {
                grouped[item.username, default: []].append(item)
            }

            var merged: [StoryItem] = []
            for (_, userStories) in grouped {
                let sorted = userStories.sorted { $0.storyId > $1.storyId }
                let latest = sorted[0]
                // 과거→최신 순서로 사진 정렬 (createdAt 기준)
                let chronological = userStories.sorted { $0.storyId < $1.storyId }
                let allPhotos = chronological.flatMap { $0.photos }.sorted {
                    let d0 = Self.parseStoryDate($0.createdAt) ?? .distantPast
                    let d1 = Self.parseStoryDate($1.createdAt) ?? .distantPast
                    return d0 < d1  // 과거 → 최신
                }
                let allIds = sorted.map { $0.storyId }
                let allSeen = sorted.allSatisfy { $0.isSeen }

                // 이미 본 스토리의 사진 수 계산 → 새 사진 시작 인덱스
                var unseenStart = 0
                for story in chronological {
                    if story.isSeen {
                        unseenStart += story.photos.count
                    } else {
                        break
                    }
                }
                // 전부 봤으면 처음부터
                if unseenStart >= allPhotos.count {
                    unseenStart = 0
                }

                merged.append(StoryItem(
                    storyId: latest.storyId,
                    storyIds: allIds,
                    profileImage: latest.profileImage,
                    bannerImage: latest.bannerImage,
                    displayName: latest.displayName,
                    username: latest.username,
                    photos: allPhotos,
                    createdAt: latest.createdAt,
                    isSeen: allSeen,
                    unseenStartIndex: unseenStart
                ))
            }

            stories = merged.sorted {
                let date0 = Self.parseStoryDate($0.createdAt) ?? .distantPast
                let date1 = Self.parseStoryDate($1.createdAt) ?? .distantPast
                return date0 > date1
            }
            print("[HomeViewModel] 스토리 \(stories.count)개 로드 완료 (합친 후)")
        } catch {
            print("[HomeViewModel] 스토리 목록 로드 실패: \(error)")
        }
    }

    /// 스토리를 봤을 때 호출 → isSeen 갱신
    func markStorySeen(storyId: Int) {
        seenStoryIds.insert(storyId)
        if let idx = stories.firstIndex(where: { $0.storyId == storyId || $0.storyIds.contains(storyId) }) {
            let old = stories[idx]
            // 모든 storyIds를 seen으로 마킹
            for id in old.storyIds {
                seenStoryIds.insert(id)
            }
            SeenStoryStore.markSeen(old.storyIds)
            stories[idx] = StoryItem(
                storyId: old.storyId,
                storyIds: old.storyIds,
                profileImage: old.profileImage,
                bannerImage: old.bannerImage,
                displayName: old.displayName,
                username: old.username,
                photos: old.photos,
                createdAt: old.createdAt,
                isSeen: true
            )

            // 피드의 스토리 테두리도 갱신
            let handle = old.username
            for i in feedPosts.indices {
                if feedPosts[i].handle == handle {
                    feedPosts[i].isStorySeen = true
                }
            }
        }
    }

    // MARK: - 피드 로드 (서버 API — 커서 기반 무한 스크롤)

    /// 첫 페이지 로드 (pull-to-refresh 또는 최초 진입)
    func loadFeed() async {
        feedPosts = []
        nextCursor = nil
        hasMoreFeed = true
        await loadMoreFeed()
    }

    /// 다음 페이지 로드 (무한 스크롤)
    func loadMoreFeed() async {
        guard !isLoadingFeed, hasMoreFeed else { return }
        isLoadingFeed = true
        defer { isLoadingFeed = false }

        do {
            let result = try await FeedService.shared.fetchFeed(cursor: nextCursor)

            // 프로필 이미지가 없는 유저들 일괄 조회
            let handles = Set(result.content.map { $0.authorHandle })
            var profileImageMap: [String: String] = [:]
            await withTaskGroup(of: (String, String?).self) { group in
                for handle in handles {
                    // 스토리에서 이미 프로필 이미지를 알고 있으면 스킵
                    if let story = stories.first(where: { $0.username == handle }), !story.profileImage.isEmpty {
                        profileImageMap[handle] = story.profileImage
                        continue
                    }
                    // 캐시에 있으면 스킵
                    if profileImageMap[handle] != nil { continue }
                    group.addTask {
                        let url = try? await ProfileService.shared.fetchUserProfile(handle: handle).profileImageUrl
                        return (handle, url)
                    }
                }
                for await (handle, url) in group {
                    if let url { profileImageMap[handle] = url }
                }
            }

            let newPosts = result.content.map { item in
                let matchedStory = stories.first(where: { $0.username == item.authorHandle })
                let profileImg = profileImageMap[item.authorHandle] ?? matchedStory?.profileImage ?? ""
                let hasStory = matchedStory != nil
                let seen = matchedStory.map { $0.storyIds.allSatisfy { SeenStoryStore.isSeen($0) } } ?? true

                return HomeFeedPost(
                    albumId: item.albumId,
                    profileImage: profileImg,
                    displayName: item.authorName,
                    handle: item.authorHandle,
                    date: Self.formatPublishedAt(item.publishedAt) ?? Self.formatAlbumDate(item.albumDate),
                    photos: item.photos.map { photo in
                        FeedPhoto(
                            frontImageUrl: photo.frontImageUrl,
                            backImageUrl: photo.backImageUrl,
                            assetName: nil
                        )
                    },
                    isLiked: item.liked ?? false,
                    likeCount: item.likeCount ?? 0,
                    commentCount: 0,
                    hasStory: hasStory,
                    isStorySeen: seen
                )
            }
            feedPosts.append(contentsOf: newPosts)
            nextCursor = result.nextCursor
            hasMoreFeed = result.hasNext
            print("[HomeViewModel] 피드 \(newPosts.count)개 로드 (total=\(feedPosts.count), hasMore=\(hasMoreFeed))")
        } catch {
            print("[HomeViewModel] 피드 로드 실패: \(error)")
        }
    }

    /// "2026-04-28" → 오늘이면 "방금 전"/"3시간 전", 아니면 "4월 28일"
    private static func parseStoryDate(_ dateStr: String?) -> Date? {
        guard let dateStr else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: dateStr) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: dateStr) { return d }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "Asia/Seoul")
        for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss"] {
            df.dateFormat = fmt
            if let d = df.date(from: dateStr) { return d }
        }
        return nil
    }

    /// publishedAt(ISO8601) → "방금 전" / "3시간 전" / "어제" / "5월 17일"
    private static func formatPublishedAt(_ dateString: String?) -> String? {
        guard let dateString, !dateString.isEmpty else { return nil }
        guard let date = parseStoryDate(dateString) else { return nil }

        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 0 { return "방금 전" }
        if seconds < 60 { return "방금 전" }
        if seconds < 3600 { return "\(seconds / 60)분 전" }
        let hours = seconds / 3600
        if hours < 24 { return "\(hours)시간 전" }

        let cal = Calendar.current
        if cal.isDateInYesterday(date) { return "어제" }

        let display = DateFormatter()
        display.dateFormat = "M월 d일"
        display.locale = Locale(identifier: "ko_KR")
        return display.string(from: date)
    }

    private static func formatAlbumDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        guard let date = formatter.date(from: dateString) else { return dateString }

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

    func toggleLike(for post: HomeFeedPost) {
        guard let idx = feedPosts.firstIndex(where: { $0.id == post.id }) else { return }
        // 즉시 UI 반영 (낙관적 업데이트)
        feedPosts[idx].isLiked.toggle()
        feedPosts[idx].likeCount += feedPosts[idx].isLiked ? 1 : -1

        let albumId = post.albumId
        Task {
            do {
                let result = try await AlbumService.shared.toggleLike(albumId: albumId)
                // 서버 응답으로 정확한 값 동기화
                if let idx = feedPosts.firstIndex(where: { $0.albumId == albumId }) {
                    feedPosts[idx].isLiked = result.liked
                    feedPosts[idx].likeCount = result.likeCount
                }
            } catch {
                // 실패 시 롤백
                if let idx = feedPosts.firstIndex(where: { $0.albumId == albumId }) {
                    feedPosts[idx].isLiked.toggle()
                    feedPosts[idx].likeCount += feedPosts[idx].isLiked ? 1 : -1
                }
                print("[HomeViewModel] 좋아요 실패: \(error)")
            }
        }
    }

    // MARK: - 게시 결과를 피드 맨 위에 추가

    /// 오늘 게시한 앨범의 사진들을 피드 맨 앞에 prepend.
    /// 사용자 정보는 임시 기본값 사용 (추후 ProfileStore 연동 가능).
    func prependPublishedPost(photos: [PhotoData],
                              displayName: String = "은찬",
                              handle: String = "silver_c_Id",
                              profileImage: String = "Profile_img") {
        let feedPhotos = photos.compactMap { photo -> FeedPhoto? in
            guard photo.backImageUrl != nil || photo.frontImageUrl != nil else { return nil }
            return FeedPhoto(frontImageUrl: photo.frontImageUrl,
                             backImageUrl: photo.backImageUrl,
                             assetName: nil)
        }
        guard !feedPhotos.isEmpty else { return }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        let dateText = formatter.string(from: Date())

        let post = HomeFeedPost(
            albumId: 0,
            profileImage: profileImage,
            displayName: displayName,
            handle: handle,
            date: dateText,
            photos: feedPhotos,
            likeCount: 0,
            commentCount: 0,
            isStorySeen: false
        )
        feedPosts.insert(post, at: 0)
    }
}
