//
//  ProfileView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        ProfileHeaderView(viewModel: viewModel)

                        GuestbookSection(viewModel: viewModel)

                            Divider()
                                .background(Color.Gray500)

                        // 피드 그리드
                        ProfileFeedGrid(
                            posts: viewModel.feedPosts,
                            displayName: viewModel.username,
                            handle: viewModel.handle,
                            profileImage: viewModel.profileImage
                        )
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .safeAreaInset(edge: .top) {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ShareLink(item: "SNAPY 프로필: @\(viewModel.handle)\nhttps://snapy.app/@\(viewModel.handle)") {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.primary)
                        }
                        .buttonStyle(.glass)

                        Button {
                            // 설정
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.primary)
                        }
                        .buttonStyle(.glass)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 4)
                }
                .background(Color.clear)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $viewModel.showEditProfile) {
                ProfileEditView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadProfile()
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
