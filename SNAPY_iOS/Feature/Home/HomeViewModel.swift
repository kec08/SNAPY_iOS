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
    let profileImage: String
    let username: String
    let date: String
    let images: [String]
    var isLiked: Bool = false
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
    @Published var showPublishSheet = false

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
                username: "silver_c_Id",
                date: "+9 7/8",
                images: ["Mock_img1", "Mock_img2", "Mock_img3", "Mock_img4"]
            ),
            HomeFeedPost(
                profileImage: "Profile_img",
                username: "silver_c_Id",
                date: "+9 7/8",
                images: ["Mock_img2", "Mock_img3"]
            ),
            HomeFeedPost(
                profileImage: "Profile_img",
                username: "silver_c_Id",
                date: "+9 7/8",
                images: ["Mock_img3", "Mock_img4", "Mock_img5"]
            ),
        ]
    }

    func toggleLike(for post: HomeFeedPost) {
        if let idx = feedPosts.firstIndex(where: { $0.id == post.id }) {
            feedPosts[idx].isLiked.toggle()
        }
    }
}
