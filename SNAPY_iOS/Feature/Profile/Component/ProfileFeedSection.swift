//
//  ProfileFeedSection.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/22/26.
//

import SwiftUI
import Kingfisher

struct ProfileFeedSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    var scrollProxy: ScrollViewProxy?

    @State private var expandedMonths: Set<Int> = []  // 펼쳐진 달 id
    @State private var monthPosts: [Int: [FeedPost]] = [:]  // 달 id → 로드된 피드
    @State private var loadingMonths: Set<Int> = []

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            // 이번 달 피드 그리드
            ForEach(viewModel.feedPosts) { post in
                NavigationLink(destination: FeedDetailView(
                    posts: viewModel.feedPosts,
                    initialPostId: post.id,
                    displayName: viewModel.username,
                    handle: viewModel.handle,
                    profileImage: viewModel.profileImage,
                    profileAsset: "Profile_img"
                )) {
                    feedThumbnail(post.thumbnailImage)
                }
            }

            // 이전 달 카드들
            ForEach(viewModel.pastMonths) { summary in
                Button {
                    toggleMonth(summary)
                } label: {
                    PastMonthCard(summary: summary)
                }
            }
        }

        // 펼쳐진 달의 그리드 (그리드 밖에 배치)
        ForEach(viewModel.pastMonths) { summary in
            if expandedMonths.contains(summary.id) {
                VStack(spacing: 0) {
                    // 달 헤더
                    HStack {
                        Text("\(summary.month)월 게시물")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textWhite)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                _ = expandedMonths.remove(summary.id)
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.customGray300)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if loadingMonths.contains(summary.id) {
                        ProgressView().tint(.white)
                            .frame(height: 100)
                    } else if let posts = monthPosts[summary.id], !posts.isEmpty {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(posts) { post in
                                NavigationLink(destination: FeedDetailView(
                                    posts: posts,
                                    initialPostId: post.id,
                                    displayName: viewModel.username,
                                    handle: viewModel.handle,
                                    profileImage: viewModel.profileImage,
                                    profileAsset: "Profile_img"
                                )) {
                                    feedThumbnail(post.thumbnailImage)
                                }
                            }
                        }
                    } else {
                        Text("게시물이 없습니다")
                            .font(.system(size: 14))
                            .foregroundColor(.customGray300)
                            .frame(height: 80)
                    }
                }
                .id("pastMonth_\(summary.id)")
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - 썸네일

    @ViewBuilder
    private func feedThumbnail(_ url: String) -> some View {
        GeometryReader { geo in
            if url.hasPrefix("http"), let imgUrl = URL(string: url) {
                KFImage(imgUrl)
                    .resizable()
                    .placeholder { Color(white: 0.15) }
                    .fade(duration: 0.2)
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    .clipped()
            } else if !url.isEmpty {
                Image(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                    .clipped()
            } else {
                Color(white: 0.15)
            }
        }
        .aspectRatio(3.0/4.0, contentMode: .fit)
    }

    // MARK: - 토글

    private func toggleMonth(_ summary: PastMonthSummary) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedMonths.contains(summary.id) {
                _ = expandedMonths.remove(summary.id)
            } else {
                expandedMonths.insert(summary.id)
                // 아직 로드 안 했으면 로드
                if monthPosts[summary.id] == nil {
                    loadingMonths.insert(summary.id)
                    Task {
                        let posts = await viewModel.loadMonthFeed(month: summary.month)
                        monthPosts[summary.id] = posts
                        loadingMonths.remove(summary.id)
                        // 로드 완료 후 해당 영역으로 스크롤
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scrollProxy?.scrollTo("pastMonth_\(summary.id)", anchor: .top)
                            }
                        }
                    }
                } else {
                    // 이미 로드됨 → 바로 스크롤
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scrollProxy?.scrollTo("pastMonth_\(summary.id)", anchor: .top)
                        }
                    }
                }
            }
        }
    }
}
