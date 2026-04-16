//
//  ProfileFeedGrid.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI

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
                        .aspectRatio(134/160, contentMode: .fit)
                        .overlay(
                            Image(post.thumbnailImage)
                                .resizable()
                                .scaledToFill()
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

// MARK: - 피드 상세 카드 (단일 게시물)
struct FeedDetailCard: View {
    let post: FeedPost
    let displayName: String
    let handle: String
    let profileImage: UIImage?
    let profileAsset: String

    @State private var currentPage = 0
    @State private var isLiked = false
    @State private var likeCount = 12
    @State private var commentCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 프로필 헤더
            HStack(spacing: 14) {
                profileImageView
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .padding(3)
                    .overlay(
                        Circle()
                            .stroke(Color.customGray500, lineWidth: 0.7)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(handle)
                        .font(.system(size: 12))
                        .foregroundColor(.customGray300)
                }

                Spacer()

                Text(post.date)
                    .font(.system(size: 13))
                    .foregroundColor(.customGray300)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // 사진 슬라이더
            TabView(selection: $currentPage) {
                ForEach(Array(post.images.enumerated()), id: \.offset) { index, imageName in
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 480)

            // 페이지 인디케이터
            if post.images.count > 1 {
                HStack(spacing: 5) {
                    ForEach(0..<post.images.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.MainYellow : Color.customGray300)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }

            // 액션 버튼
            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    Button {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 26))
                            .foregroundColor(isLiked ? .red : .white)
                    }
                    Text("\(likeCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                HStack(spacing: 8) {
                    Button {
                        // 댓글
                    } label: {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    Text("\(commentCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                Button {
                    // 공유
                } label: {
                    Image(systemName: "paperplane")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 20)

            // 이미지 댓글 영역
            ImageCommentSection()
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let image = profileImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(profileAsset)
                .resizable()
                .scaledToFill()
        }
    }
}

// MARK: - Preview
#Preview("ProfileFeedGrid") {
    NavigationStack {
        ScrollView {
            ProfileFeedGrid(
                posts: [
                    FeedPost(thumbnailImage: "Mock_img1", images: ["Mock_img1"], date: "2026. 4. 1."),
                    FeedPost(thumbnailImage: "Mock_img2", images: ["Mock_img2"], date: "2026. 4. 2."),
                    FeedPost(thumbnailImage: "Mock_img3", images: ["Mock_img3"], date: "2026. 4. 3."),
                    FeedPost(thumbnailImage: "Mock_img4", images: ["Mock_img4"], date: "2026. 4. 4."),
                    FeedPost(thumbnailImage: "Mock_img5", images: ["Mock_img5"], date: "2026. 4. 5."),
                ],
                displayName: "김은찬",
                handle: "silver_c.ld"
            )
        }
        .background(Color.backgroundBlack)
    }
}

#Preview("FeedDetailView") {
    let samplePosts = [
        FeedPost(thumbnailImage: "Mock_img1", images: ["Mock_img1", "Mock_img2"], date: "2026. 4. 1."),
        FeedPost(thumbnailImage: "Mock_img2", images: ["Mock_img2", "Mock_img3"], date: "2026. 4. 2."),
        FeedPost(thumbnailImage: "Mock_img3", images: ["Mock_img3"], date: "2026. 4. 3."),
    ]
    return NavigationStack {
        FeedDetailView(
            posts: samplePosts,
            initialPostId: samplePosts[0].id,
            displayName: "김은찬",
            handle: "silver_c.ld",
            profileImage: nil,
            profileAsset: "Profile_img"
        )
    }
}
