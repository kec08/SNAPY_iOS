//
//  ProfileFeedGrid.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI

struct ProfileFeedGrid: View {
    let posts: [FeedPost]

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(posts) { post in
                NavigationLink(destination: FeedDetailView(post: post)) {
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

// MARK: - 피드 상세
struct FeedDetailView: View {
    let post: FeedPost

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 이미지 슬라이더
                    TabView {
                        ForEach(post.images, id: \.self) { imageName in
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(width: 402, height: 482)
                                .clipped()
                        }
                    }
                    .frame(width: 402, height: 482)
                    .tabViewStyle(.page(indexDisplayMode: .always))

                    // 날짜
                    Text(post.date)
                        .font(.system(size: 13))
                        .foregroundColor(.customGray300)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview("ProfileFeedGrid") {
    NavigationStack {
        ScrollView {
            ProfileFeedGrid(posts: [
                FeedPost(thumbnailImage: "Mock_img1", images: ["Mock_img1"], date: "2026. 4. 1."),
                FeedPost(thumbnailImage: "Mock_img2", images: ["Mock_img2"], date: "2026. 4. 2."),
                FeedPost(thumbnailImage: "Mock_img3", images: ["Mock_img3"], date: "2026. 4. 3."),
                FeedPost(thumbnailImage: "Mock_img4", images: ["Mock_img4"], date: "2026. 4. 4."),
                FeedPost(thumbnailImage: "Mock_img5", images: ["Mock_img5"], date: "2026. 4. 5."),
            ])
        }
        .background(Color.backgroundBlack)
    }
}

#Preview("FeedDetailView") {
    NavigationStack {
        FeedDetailView(post: FeedPost(
            thumbnailImage: "Mock_img1",
            images: ["Mock_img1", "Mock_img2", "Mock_img3"],
            date: "2026. 4. 1."
        ))
    }
}
