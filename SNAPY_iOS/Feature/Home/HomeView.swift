//
//  HomeView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    // 스토리 전체화면 표시용 (피드에서 탭 — 해당 유저 스토리만)
    @State private var singleStoryItem: StoryItem? = nil
    // 프로필 네비게이션용
    @State private var profileNavHandle: String? = nil
    @State private var profileNavName: String = ""
    @State private var profileNavImage: String? = nil
    // Pull-to-refresh
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.backgroundBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 헤더
                        HomeHeader()

                        // Pull-to-refresh 로딩바 (헤더 바로 아래)
                        if isRefreshing {
                            ProgressView()
                                .tint(.white)
                                .padding(.vertical, 12)
                        }

                        // 스토리
                        HomeStoryBar(
                            stories: viewModel.stories,
                            onStorySeen: { storyId in
                                viewModel.markStorySeen(storyId: storyId)
                            }
                        )

                        // 피드
                        LazyVStack(spacing: 30) {
                            ForEach(viewModel.feedPosts) { post in
                                HomeFeedCard(
                                    post: post,
                                    onLike: { viewModel.toggleLike(for: post) },
                                    onProfileImageTap: {
                                        handleProfileImageTap(post: post)
                                    },
                                    onNameTap: {
                                        navigateToProfile(post: post)
                                    }
                                )
                                .onAppear {
                                    if post.id == viewModel.feedPosts.last?.id {
                                        Task { await viewModel.loadMoreFeed() }
                                    }
                                }
                            }
                        }

                        // 로딩 인디케이터 (다음 페이지)
                        if viewModel.isLoadingFeed {
                            ProgressView()
                                .tint(.white)
                                .padding(.vertical, 20)
                        }

                        // 피드 끝 메시지
                        if !viewModel.hasMoreFeed {
                            HomeFeedEndView()
                                .padding(.vertical, 40)
                        }
                    }
                    // 스크롤 위치 감지 → pull-to-refresh
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                                    // 헤더 높이(~41) + 여유 → 70pt 이상 당기면 새로고침
                                    if newValue > 140 && !isRefreshing {
                                        triggerRefresh()
                                    }
                                }
                        }
                    )
                }
                // 홈 화면 최초 진입 시 로드
                .onAppear {
                    Task {
                        async let stories: () = viewModel.loadStories()
                        async let feed: () = viewModel.loadFeed()
                        _ = await (stories, feed)
                    }
                }

                // 게시 버튼
                NavigationLink {
                    PublishPreviewView(homeViewModel: viewModel)
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.backgroundBlack)
                        .frame(width: 56, height: 56)
                        .background(Color.white, in: Circle())
                        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                }
                .padding(.trailing, 14)
                .padding(.bottom, 24)
            }
            // 프로필 네비게이션
            .navigationDestination(isPresented: Binding(
                get: { profileNavHandle != nil },
                set: { if !$0 { profileNavHandle = nil } }
            )) {
                if let handle = profileNavHandle {
                    FriendProfileView(
                        name: profileNavName,
                        handle: handle,
                        profileImageUrl: profileNavImage
                    )
                }
            }
            // 피드에서 탭한 유저의 스토리만 표시
            .fullScreenCover(item: $singleStoryItem) { story in
                StoryDetailView(
                    stories: [story],
                    initialIndex: 0,
                    onStorySeen: { storyId in
                        viewModel.markStorySeen(storyId: storyId)
                    }
                )
            }
        }
    }

    // MARK: - Pull-to-refresh

    private func triggerRefresh() {
        isRefreshing = true
        Task {
            async let stories: () = viewModel.loadStories()
            async let feed: () = viewModel.loadFeed()
            async let delay: () = Task.sleep(nanoseconds: 500_000_000)
            _ = try? await (stories, feed, delay)
            isRefreshing = false
        }
    }

    // MARK: - 프로필 사진 탭 (스토리 있으면 스토리, 없으면 프로필)

    private func handleProfileImageTap(post: HomeFeedPost) {
        if let story = viewModel.stories.first(where: { $0.username == post.handle }) {
            singleStoryItem = story
        } else {
            navigateToProfile(post: post)
        }
    }

    // MARK: - 이름 탭 (무조건 프로필)

    private func navigateToProfile(post: HomeFeedPost) {
        profileNavName = post.displayName
        profileNavImage = post.profileImage.isEmpty ? nil : post.profileImage
        profileNavHandle = post.handle
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
