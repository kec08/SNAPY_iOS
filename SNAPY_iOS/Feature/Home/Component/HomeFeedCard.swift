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

    @State private var currentPage = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 프로필 헤더
            HStack(spacing: 14) {
                // 프로필 사진
                Button {
                    // 스토리 화면 이동
                } label: {
                    Image(post.profileImage)
                        .resizable()
                        .scaledToFill()
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

                HStack(spacing: 8) {
                    Button {
                        // 댓글
                    } label: {
                        Image("Chat_icon")
                            .resizable()
                            .frame(width: 26, height: 26)
                    }
                    Text("\(post.commentCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                Button {
                    // 공유
                } label: {
                    Image("Share_icon")
                        .resizable()
                        .frame(width: 24, height: 24)
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
}

// MARK: - 이미지 댓글 섹션

struct ImageCommentSection: View {
    @State private var showImagePicker = false

    // 임시 이미지 반응 목데이터
    private let reactions = ["Mock_img2", "Mock_img3"]

    var body: some View {
        HStack(spacing: 12) {
            // 이미지 추가 버튼 (원형, 점선 테두리)
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

            // 이미지 반응들 (원형)
            ForEach(reactions, id: \.self) { imageName in
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            }

            Spacer()

            Button {
                // 댓글 작성 화면 이동
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
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
                images: ["Mock_img1", "Mock_img2", "Mock_img3"],
                likeCount: 12,
                commentCount: 3,
                isStorySeen: false
            ),
            onLike: {}
        )
    }
    .background(Color.backgroundBlack)
}
