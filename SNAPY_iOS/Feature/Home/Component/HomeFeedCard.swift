//
//  HomeFeedCard.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI

struct HomeFeedCard: View {
    let post: HomeFeedPost
    var onLike: () -> Void
    var onProfileImageTap: (() -> Void)? = nil
    var onNameTap: (() -> Void)? = nil

    @State private var isLiked: Bool
    @State private var likeCount: Int

    init(post: HomeFeedPost, onLike: @escaping () -> Void,
         onProfileImageTap: (() -> Void)? = nil, onNameTap: (() -> Void)? = nil) {
        self.post = post
        self.onLike = onLike
        self.onProfileImageTap = onProfileImageTap
        self.onNameTap = onNameTap
        _isLiked = State(initialValue: post.isLiked)
        _likeCount = State(initialValue: post.likeCount)
    }

    var body: some View {
        FeedCardView(
            profileImageSource: profileSource,
            displayName: post.displayName,
            handle: post.handle,
            date: post.date,
            photos: post.photos.map {
                FeedCardPhoto(frontImageUrl: $0.frontImageUrl, backImageUrl: $0.backImageUrl, assetName: $0.assetName)
            },
            hasStory: post.hasStory,
            isStorySeen: post.isStorySeen,
            isLiked: $isLiked,
            likeCount: $likeCount,
            commentCount: post.commentCount,
            onLike: { onLike() },
            onProfileImageTap: onProfileImageTap,
            onNameTap: onNameTap
        )
    }

    private var profileSource: ProfileImageSource {
        if post.profileImage.isImageURL {
            return .url(post.profileImage)
        } else if !post.profileImage.isEmpty {
            return .asset(post.profileImage)
        }
        return .none
    }
}

// MARK: - Preview

#Preview("HomeFeedCard") {
    ScrollView {
        HomeFeedCard(
            post: HomeFeedPost(
                profileImage: "Profile_img",
                displayName: "김은찬",
                handle: "silver_c_Id",
                date: "4월 15일",
                photos: [
                    FeedPhoto(frontImageUrl: nil, backImageUrl: nil, assetName: "Mock_img1"),
                    FeedPhoto(frontImageUrl: nil, backImageUrl: nil, assetName: "Mock_img2"),
                ],
                likeCount: 12,
                commentCount: 3,
                hasStory: true,
                isStorySeen: false
            ),
            onLike: {}
        )
    }
    .background(Color.backgroundBlack)
}
