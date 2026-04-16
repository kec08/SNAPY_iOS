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

struct HomeFeedPost: Identifiable {
    let id = UUID()
    let profileImage: String        // asset 이름 또는 URL (http로 시작하면 URL로 인식)
    let displayName: String
    let handle: String
    let date: String
    let images: [String]            // asset 이름 또는 URL 혼용 가능
    var isLiked: Bool = false
    var likeCount: Int = 0
    var commentCount: Int = 0
    var isStorySeen: Bool = true
}

extension String {
    /// 이미지 문자열이 URL인지 (http/https로 시작) — 피드/스토리에서 asset vs URL 분기에 사용
    var isImageURL: Bool { hasPrefix("http") }
}

struct StoryItem: Identifiable {
    let id = UUID()
    let profileImage: String
    let bannerImage: String
    let username: String
    let isSeen: Bool
}

// MARK: - ViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var stories: [StoryItem] = []
    @Published var feedPosts: [HomeFeedPost] = []

    init() {
        loadMockData()
    }

    private func loadMockData() {
        stories = [
            StoryItem(profileImage: "Profile_img", bannerImage: "Mock_img1", username: "내 스토리", isSeen: false),
            StoryItem(profileImage: "Mock_img1", bannerImage: "Mock_img2", username: "silver_c_Id", isSeen: false),
            StoryItem(profileImage: "Mock_img2", bannerImage: "Mock_img3", username: "user_02", isSeen: false),
            StoryItem(profileImage: "Mock_img3", bannerImage: "Mock_img4", username: "user_03", isSeen: true),
            StoryItem(profileImage: "Mock_img4", bannerImage: "Mock_img5", username: "user_04", isSeen: false),
            StoryItem(profileImage: "Mock_img5", bannerImage: "Mock_img1", username: "user_05", isSeen: true),
        ]

        feedPosts = [
            HomeFeedPost(
                profileImage: "Profile_img",
                displayName: "은찬",
                handle: "silver_c_Id",
                date: "4월 15일",
                images: ["Mock_img1", "Mock_img2", "Mock_img3", "Mock_img4"],
                likeCount: 12,
                commentCount: 3,
                isStorySeen: false
            ),
            HomeFeedPost(
                profileImage: "Profile_img",
                displayName: "은찬",
                handle: "silver_c_Id",
                date: "4월 14일",
                images: ["Mock_img2", "Mock_img3"],
                likeCount: 5,
                commentCount: 1,
                isStorySeen: true
            ),
            HomeFeedPost(
                profileImage: "Profile_img",
                displayName: "은찬",
                handle: "silver_c_Id",
                date: "4월 13일",
                images: ["Mock_img3", "Mock_img4", "Mock_img5"],
                likeCount: 24,
                commentCount: 7,
                isStorySeen: false
            ),
        ]
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
        let urls = photos.compactMap { $0.backImageUrl }.filter { !$0.isEmpty }
        guard !urls.isEmpty else { return }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        let dateText = formatter.string(from: Date())

        let post = HomeFeedPost(
            profileImage: profileImage,
            displayName: displayName,
            handle: handle,
            date: dateText,
            images: urls,
            likeCount: 0,
            commentCount: 0,
            isStorySeen: false
        )
        feedPosts.insert(post, at: 0)
    }
}
