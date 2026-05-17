//
//  HomeStoryBar.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI
import Kingfisher

private struct StoryPresentation: Identifiable {
    let id = UUID()
    let index: Int
    let stories: [StoryItem]
}

struct HomeStoryBar: View {
    let stories: [StoryItem]
    var onStorySeen: ((Int) -> Void)?   // storyId를 전달해서 본 것으로 마킹
    @State private var storyPresentation: StoryPresentation?

    private var sortedStories: [StoryItem] {
        stories.sorted {
            let seen0 = $0.storyIds.allSatisfy { SeenStoryStore.isSeen($0) }
            let seen1 = $1.storyIds.allSatisfy { SeenStoryStore.isSeen($0) }

            // 1순위: 안 본 스토리(노란 테두리)가 앞
            if seen0 != seen1 {
                return !seen0
            }

            // 2순위: 본 스토리는 읽은 순서 — 최근에 읽은 게 뒤로
            if seen0 && seen1 {
                let time0 = $0.storyIds.map { SeenStoryStore.seenTime($0) }.max() ?? 0
                let time1 = $1.storyIds.map { SeenStoryStore.seenTime($0) }.max() ?? 0
                return time0 < time1  // 최근에 읽은 게 뒤
            }

            return false
        }
    }

    var body: some View {
        let currentSorted = sortedStories

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 13) {
                ForEach(Array(currentSorted.enumerated()), id: \.element.id) { index, story in
                    Button {
                        storyPresentation = StoryPresentation(index: index, stories: currentSorted)
                    } label: {
                        storyCard(story: story)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .fullScreenCover(item: $storyPresentation) { presentation in
            StoryDetailView(
                stories: presentation.stories,
                initialIndex: presentation.index,
                onStorySeen: onStorySeen
            )
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
                storyImageView(name: story.bannerImage)
                    .frame(width: 60, height: 100)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // 어두운 오버레이
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 60, height: 100)

                // 프로필 사진
                storyImageView(name: story.profileImage)
                    .frame(width: 36, height: 36)
                    .clipped()
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
                        lineWidth: 0.7
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

    /// URL이면 KFImage(캐싱), 아니면 로컬 Image
    @ViewBuilder
    private func storyImageView(name: String) -> some View {
        if name.isImageURL, let url = URL(string: name) {
            KFImage(url)
                .resizable()
                .placeholder { Color.customGray500 }
                .fade(duration: 0.2)
                .scaledToFill()
        } else if !name.isEmpty {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            Image("Profile_img")
                .resizable()
                .scaledToFill()
        }
    }
}

struct HomeFeed_Previews: PreviewProvider {
    static var previews: some View {
        HomeStoryBar(
            stories: [
                StoryItem(storyId: 1, profileImage: "Profile_img", bannerImage: "Mock_img1", displayName: "은찬", username: "eunchan", photos: [], createdAt: nil, isSeen: false),
                StoryItem(storyId: 2, profileImage: "Profile_img", bannerImage: "Mock_img2", displayName: "민수", username: "user_02", photos: [], createdAt: nil, isSeen: true),
            ]
        )
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
