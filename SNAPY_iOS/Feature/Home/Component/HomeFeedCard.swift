//
//  HomeFeedCard.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI
import Kingfisher

struct HomeFeedCard: View {
    let post: HomeFeedPost
    var onLike: () -> Void

    @State private var currentPage = 0
    @State private var showComments = false
    @State private var heartAnimations: [HeartAnimation] = []
    @State private var heartTapCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 프로필 헤더
            HStack(spacing: 14) {
                // 프로필 사진
                Button {
                    // 스토리 화면 이동
                } label: {
                    profileImageView
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .padding(3)
                        .overlay(
                            Circle()
                                .stroke(
                                    post.isStorySeen
                                        ? AnyShapeStyle(Color.customGray500)
                                        : AnyShapeStyle(
                                            LinearGradient(
                                                colors: [Color(hex: "FFC83D"), Color(hex: "FF9F1C")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        ),
                                    lineWidth: 0.7
                                )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(post.handle)
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
            ZStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(post.photos.enumerated()), id: \.offset) { index, photo in
                        feedPhotoView(for: photo)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // 더블탭 하트 애니메이션들
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
            .frame(height: 480)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { location in
                triggerHeartAnimation(at: location)
                if !post.isLiked {
                    onLike()
                }
            }

            // 페이지 인디케이터
            if post.photos.count > 1 {
                HStack(spacing: 5) {
                    ForEach(0..<post.photos.count, id: \.self) { index in
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
                        onLike()
                    } label: {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 26))
                            .foregroundColor(post.isLiked ? .red : .white)
                    }
                    Text("\(post.likeCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                HStack(spacing: 6) {
                    Button {
                        showComments = true
                    } label: {
                        Image("Chat_icon")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    Text("\(post.commentCount)")
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
            CommentSheetView(postId: post.id)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - 더블탭 하트

    private func triggerHeartAnimation(at location: CGPoint) {
        heartTapCount += 1
        let size: CGFloat = 60 + CGFloat(heartTapCount - 1) * 2
        let heart = HeartAnimation(position: location, size: min(size, 120))
        heartAnimations.append(heart)

        // 커지면서 나타남
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            if let idx = heartAnimations.firstIndex(where: { $0.id == heart.id }) {
                heartAnimations[idx].scale = 1.2
                heartAnimations[idx].opacity = 1.0
            }
        }

        // 잠시 후 사라짐
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                if let idx = heartAnimations.firstIndex(where: { $0.id == heart.id }) {
                    heartAnimations[idx].scale = 1.6
                    heartAnimations[idx].opacity = 0
                }
            }
        }

        // 완전 제거
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            heartAnimations.removeAll { $0.id == heart.id }
        }
    }

    // MARK: - 이미지 분기 (asset vs URL)

    @ViewBuilder
    private var profileImageView: some View {
        if post.profileImage.isImageURL, let url = URL(string: post.profileImage) {
            KFImage(url)
                .resizable()
                .placeholder { Color.customGray500 }
                .fade(duration: 0.2)
                .scaledToFill()
        } else {
            Image(post.profileImage)
                .resizable()
                .scaledToFill()
        }
    }

    @ViewBuilder
    private func feedPhotoView(for photo: FeedPhoto) -> some View {
        ZStack(alignment: .topLeading) {
            // 배경: back 이미지 (또는 에셋)
            if let backUrl = photo.backImageUrl, let url = URL(string: backUrl) {
                KFImage(url)
                    .resizable()
                    .placeholder { Color.customGray500 }
                    .fade(duration: 0.2)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if let asset = photo.assetName {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                Color.customGray500
            }

            // PIP: front 이미지
            if let frontUrl = photo.frontImageUrl, let url = URL(string: frontUrl) {
                KFImage(url)
                    .resizable()
                    .placeholder { Color.clear }
                    .fade(duration: 0.2)
                    .scaledToFill()
                    .frame(width: 100, height: 130)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.top, 12)
                    .padding(.leading, 12)
            }
        }
    }
}

// MARK: - 이미지 댓글 섹션

struct ImageCommentSection: View {
    @State private var showImagePicker = false

    // 임시 이미지 반응 목데이터
    private let reactions = ["Mock_img2", "Mock_img3", "Mock_img4", "Mock_img5", "Mock_img1", "Mock_img2", "Mock_img3", "Mock_img4"]

    var body: some View {
        HStack(spacing: 12) {
            // 이미지 추가 버튼 (고정)
            Button {
                showImagePicker = true
            } label: {
                Circle()
                    .stroke(Color.customGray300, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.customGray300)
                    )
            }

            // 반응 이미지들 (가로 스크롤)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(reactions.indices, id: \.self) { index in
                        Image(reactions[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}

// MARK: - 하트 애니메이션 모델

struct HeartAnimation: Identifiable {
    let id = UUID()
    let position: CGPoint
    let rotation: Double = Double.random(in: -30...30)
    var size: CGFloat = 60
    var scale: CGFloat = 0.0
    var opacity: Double = 0.0
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
                    FeedPhoto(frontImageUrl: nil, backImageUrl: nil, assetName: "Mock_img3"),
                ],
                likeCount: 12,
                commentCount: 3,
                isStorySeen: false
            ),
            onLike: {}
        )
    }
    .background(Color.backgroundBlack)
}
