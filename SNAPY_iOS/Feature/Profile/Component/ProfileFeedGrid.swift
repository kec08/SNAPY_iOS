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
                    Image(post.thumbnailImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 130)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
            }
        }
    }
}

// MARK: - 피드 상세 (인스타처럼 사진 1~5장 스와이프)
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
                                .frame(height: 400)
                                .clipped()
                        }
                    }
                    .frame(height: 400)
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
