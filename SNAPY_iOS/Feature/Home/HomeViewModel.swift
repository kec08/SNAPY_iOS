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
    let storyId: Int           // 서버 스토리 ID (상세 조회/좋아요에 사용)
    let profileImage: String
    let bannerImage: String
    let displayName: String
    let username: String       // handle
    let photos: [StoryPhotoSet]  // 서버의 사진 세트 (front/back + type)
    let createdAt: String?     // ISO8601 서버 시각
    let isSeen: Bool

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

    /// 이미 본 스토리 ID (로컬 관리 — 서버에 isSeen API가 없으므로)
    private var seenStoryIds: Set<Int> {
        get { Set((UserDefaults.standard.array(forKey: "seenStoryIds") as? [Int]) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "seenStoryIds") }
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
                            return await StoryItem(
                                storyId: story.storyId,
                                profileImage: story.profileImageUrl ?? "",
                                bannerImage: story.thumbnailUrl ?? "",
                                displayName: detail.username,
                                username: detail.handle,
                                photos: detail.photos,
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

            // storyId 순서 유지
            stories = items.sorted { $0.storyId < $1.storyId }
            print("[HomeViewModel] 스토리 \(stories.count)개 로드 완료")
        } catch {
            print("[HomeViewModel] 스토리 목록 로드 실패: \(error)")
        }
    }

    /// 스토리를 봤을 때 호출 → isSeen 갱신
    func markStorySeen(storyId: Int) {
        seenStoryIds.insert(storyId)
        if let idx = stories.firstIndex(where: { $0.storyId == storyId }) {
            let old = stories[idx]
            stories[idx] = StoryItem(
                storyId: old.storyId,
                profileImage: old.profileImage,
                bannerImage: old.bannerImage,
                displayName: old.displayName,
                username: old.username,
                photos: old.photos,
                createdAt: old.createdAt,
                isSeen: true
            )
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
            let newPosts = result.content.map { item in
                // 해당 유저의 스토리가 있는지 확인 → 프로필 이미지 & 스토리 상태 연동
                let matchedStory = stories.first(where: { $0.username == item.authorHandle })
                let profileImg = matchedStory?.profileImage ?? ""
                let hasStory = matchedStory != nil
                let seen = matchedStory.map { seenStoryIds.contains($0.storyId) } ?? true

                return HomeFeedPost(
                    albumId: item.albumId,
                    profileImage: profileImg,
                    displayName: item.authorName,
                    handle: item.authorHandle,
                    date: Self.formatAlbumDate(item.albumDate),
                    photos: item.photos.map { photo in
                        FeedPhoto(
                            frontImageUrl: photo.frontImageUrl,
                            backImageUrl: photo.backImageUrl,
                            assetName: nil
                        )
                    },
                    likeCount: 0,
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

    /// "2026-04-28" → "4월 28일"
    private static func formatAlbumDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        guard let date = formatter.date(from: dateString) else { return dateString }
        let display = DateFormatter()
        display.dateFormat = "M월 d일"
        display.locale = Locale(identifier: "ko_KR")
        return display.string(from: date)
    }

    func toggleLike(for post: HomeFeedPost) {
        if let idx = feedPosts.firstIndex(where: { $0.id == post.id }) {
            feedPosts[idx].isLiked.toggle()
            feedPosts[idx].likeCount += feedPosts[idx].isLiked ? 1 : -1
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
