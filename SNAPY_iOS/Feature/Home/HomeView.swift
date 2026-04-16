//
//  HomeView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.backgroundBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 헤더
                        HomeHeader()

                        // 스토리
                        HomeStoryBar(stories: viewModel.stories)

                        // 피드
                        LazyVStack(spacing: 30) {
                            ForEach(viewModel.feedPosts) { post in
                                HomeFeedCard(
                                    post: post,
                                    onLike: { viewModel.toggleLike(for: post) }
                                )
                            }
                        }

                        // 피드 끝 메시지
                        HomeFeedEndView()
                            .padding(.vertical, 40)
                    }
                }

                // 게시 플로팅 버튼 → 페이지 단위로 이동
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
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
