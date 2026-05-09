//
//  ProfileView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundBlack.ignoresSafeArea()

                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 30) {
                            // Pull-to-refresh 로딩바 (배너 위)
                            if isRefreshing {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.top, 60)
                            }

                            ProfileHeaderView(viewModel: viewModel)

                            GuestbookSection(viewModel: viewModel)

                                Divider()
                                    .background(Color.Gray500)

                            // 이번 달 피드 그리드 + 이전 달 카드 통합
                            ProfileFeedSection(
                                viewModel: viewModel,
                                scrollProxy: scrollProxy
                            )
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                                        if newValue > 140 && !isRefreshing {
                                            isRefreshing = true
                                            Task {
                                                await viewModel.loadProfile()
                                                try? await Task.sleep(nanoseconds: 500_000_000)
                                                isRefreshing = false
                                            }
                                        }
                                    }
                            }
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
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.primary)
                        }
                        .buttonStyle(.glass)

                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20, weight: .semibold))
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
