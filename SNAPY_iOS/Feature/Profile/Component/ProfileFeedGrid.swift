//
//  ProfileFeedGrid.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import Kingfisher

struct ProfileFeedGrid: View {
    let posts: [FeedPost]
    let displayName: String
    let handle: String
    let profileImage: UIImage?
    let profileAsset: String

    init(
        posts: [FeedPost],
        displayName: String = "",
        handle: String = "",
        profileImage: UIImage? = nil,
        profileAsset: String = "Profile_img"
    ) {
        self.posts = posts
        self.displayName = displayName
        self.handle = handle
        self.profileImage = profileImage
        self.profileAsset = profileAsset
    }

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(posts) { post in
                NavigationLink(destination: FeedDetailView(
                    posts: posts,
                    initialPostId: post.id,
                    displayName: displayName,
                    handle: handle,
                    profileImage: profileImage,
                    profileAsset: profileAsset
                )) {
                    Color.clear
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                        .overlay(
                            Group {
                                if post.thumbnailImage.hasPrefix("http"),
                                   let url = URL(string: post.thumbnailImage) {
                                    KFImage(url)
                                        .resizable()
                                        .placeholder { Color(white: 0.15) }
                                        .fade(duration: 0.2)
                                        .scaledToFill()
                                } else {
                                    Image(post.thumbnailImage)
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                        )
                        .clipped()
                }
            }
        }
    }
}

// MARK: - 피드 상세 (세로 스크롤로 다음 피드 연결)
struct FeedDetailView: View {
    let posts: [FeedPost]
    let initialPostId: FeedPost.ID
    let displayName: String
    let handle: String
    let profileImage: UIImage?
    let profileAsset: String

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 30) {
                        ForEach(posts) { post in
                            FeedDetailCard(
                                post: post,
                                displayName: displayName,
                                handle: handle,
                                profileImage: profileImage,
                                profileAsset: profileAsset
                            )
                            .id(post.id)
                        }
                    }
                }
                .onAppear {
                    proxy.scrollTo(initialPostId, anchor: .top)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 피드 상세 카드
struct FeedDetailCard: View {
    let post: FeedPost
    let displayName: String
    let handle: String
    let profileImage: UIImage?
    let profileAsset: String

    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var commentCount = 0

    var body: some View {
        FeedCardView(
            albumId: post.id,
            profileImageSource: profileSource,
            displayName: displayName,
            handle: handle,
            date: post.date,
            photos: post.photos.map {
                FeedCardPhoto(frontImageUrl: $0.frontImageUrl, backImageUrl: $0.backImageUrl, assetName: nil)
            },
            isLiked: $isLiked,
            likeCount: $likeCount,
            commentCount: $commentCount
        )
    }

    private var profileSource: ProfileImageSource {
        if let image = profileImage {
            return .uiImage(image)
        } else if !profileAsset.isEmpty {
            return .asset(profileAsset)
        }
        return .none
    }
}

// MARK: - Preview
#Preview("ProfileFeedGrid") {
    NavigationStack {
        ScrollView {
            ProfileFeedGrid(
                posts: [
                    FeedPost(id: 1, thumbnailImage: "Mock_img1", photos: [], date: "2026.04.01"),
                    FeedPost(id: 2, thumbnailImage: "Mock_img2", photos: [], date: "2026.04.02"),
                ],
                displayName: "김은찬",
                handle: "silver_c.ld"
            )
        }
        .background(Color.backgroundBlack)
    }
}
