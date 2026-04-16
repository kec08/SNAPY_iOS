//
//  HomeStoryBar.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI

struct HomeStoryBar: View {
    let stories: [StoryItem]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 13) {
                ForEach(stories) { story in
                    Button {
                        // 스토리 화면 이동
                    } label: {
                        storyCard(story: story)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }

    @ViewBuilder
    private func storyCard(story: StoryItem) -> some View {
        let borderColors: [Color] = story.isSeen
            ? [.customGray500, .customGray300]
            : [Color(hex: "FFC83D"), Color(hex: "FF9F1C")]

        VStack(spacing: 6) {
            ZStack {
                // 배너 배경
                Image(story.bannerImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // 어두운 오버레이
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 60, height: 100)

                // 프로필 사진
                Image(story.profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.backgroundBlack, lineWidth: 1)
                    )
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(
                        LinearGradient(
                            colors: borderColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )

            // 유저네임 (카드 밖)
            Text(story.username)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 66)
                .padding(.top, 5)
        }
    }
}

struct HomeFeed_Previews: PreviewProvider {
    static var previews: some View {
        HomeStoryBar(
            stories: [
                StoryItem(profileImage: "Profile_img", bannerImage: "Mock_img1", username: "eunchan", isSeen: false),
                StoryItem(profileImage: "Profile_img", bannerImage: "Mock_img2", username: "user_02", isSeen: true),
                StoryItem(profileImage: "Profile_img", bannerImage: "Mock_img3", username: "user_03", isSeen: false),
            ]
        )
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
