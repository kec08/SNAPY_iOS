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

// MARK: - 피드 상세 카드 (단일 게시물)
struct FeedDetailCard: View {
    let post: FeedPost
    let displayName: String
    let handle: String
    let profileImage: UIImage?
    let profileAsset: String

    @State private var currentPage = 0
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var commentCount = 0
    @State private var showComments = false
    @State private var heartAnimations: [HeartAnimation] = []
    @State private var heartTapCount: Int = 0

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

            // 사진 슬라이더 (back 배경 + front 드래그 PIP + 더블탭 하트)
            ZStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(post.photos.enumerated()), id: \.offset) { index, photo in
                        GeometryReader { geo in
                            ZStack(alignment: .topLeading) {
                                // back 이미지
                                if let backUrl = photo.backImageUrl, let url = URL(string: backUrl) {
                                    KFImage(url)
                                        .resizable()
                                        .placeholder { Color(white: 0.15) }
                                        .fade(duration: 0.2)
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .clipped()
                                } else {
                                    Color(white: 0.15)
                                }

                                // front 드래그 가능 PIP
                                if let frontUrl = photo.frontImageUrl, let url = URL(string: frontUrl) {
                                    DraggablePIP(
                                        containerSize: geo.size,
                                        pipWidth: 120,
                                        pipHeight: 160,
                                        padding: 12
                                    ) {
                                        KFImage(url)
                                            .resizable()
                                            .placeholder { Color(white: 0.2) }
                                            .fade(duration: 0.2)
                                            .scaledToFill()
                                    }
                                }
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // 더블탭 하트 애니메이션
                ForEach(heartAnimations) { heart in
                    Image("Heart_img")
                        .resizable()
                        .scaledToFit()
                        .frame(width: heart.size, height: heart.size)
                        .rotationEffect(.degrees(heart.rotation))
                        .scaleEffect(heart.scale)
                        .opacity(heart.opacity)
                        .position(heart.position)
                }
            }
            .frame(height: 540)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { location in
                triggerHeartAnimation(at: location)
                if !isLiked {
                    isLiked = true
                    likeCount += 1
                }
            }

            // 페이지 인디케이터 (1개여도 간격 유지)
            HStack(spacing: 5) {
                if post.photos.count > 1 {
                    ForEach(0..<post.photos.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.MainYellow : Color.customGray300)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 6)
            .padding(.vertical, 14)

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
                        showComments = true
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
        .sheet(isPresented: $showComments) {
            CommentSheetView(postId: UUID())
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - 더블탭 하트

    private func triggerHeartAnimation(at location: CGPoint) {
        heartTapCount += 1
        let size: CGFloat = 60 + CGFloat(heartTapCount - 1) * 2
        let heart = HeartAnimation(position: location, size: min(size, 120))
        heartAnimations.append(heart)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            if let idx = heartAnimations.firstIndex(where: { $0.id == heart.id }) {
                heartAnimations[idx].scale = 1.2
                heartAnimations[idx].opacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                if let idx = heartAnimations.firstIndex(where: { $0.id == heart.id }) {
                    heartAnimations[idx].scale = 1.6
                    heartAnimations[idx].opacity = 0
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            heartAnimations.removeAll { $0.id == heart.id }
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
