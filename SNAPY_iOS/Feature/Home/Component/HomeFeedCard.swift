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
            HStack(spacing: 10) {
                Image(post.profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())

                Text(post.username)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text(post.date)
                    .font(.system(size: 13))
                    .foregroundColor(.customGray300)
            }
            .padding(.horizontal, 16)
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
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 480)

            // 액션 버튼
            HStack(spacing: 18) {
                Button {
                    onLike()
                } label: {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(post.isLiked ? .red : .white)
                }

                Button {
                    // 댓글 (임시)
                } label: {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Button {
                    // 공유 (임시)
                } label: {
                    Image(systemName: "paperplane")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // 이미지 댓글 영역
            ImageCommentSection()
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - 이미지 댓글 섹션

struct ImageCommentSection: View {
    @State private var showImagePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 기존 이미지 댓글 (목데이터)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { _ in
                        Image("Mock_img2")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // 이미지 추가 버튼
                    Button {
                        showImagePicker = true
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.customGray300)
                            )
                    }
                }
            }
        }
    }
}
