//
//  FriendView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct FriendView: View {
    @StateObject private var viewModel = FriendViewModel()
    @State private var showFriendRequest = false
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    FriendHeaderView(pendingCount: viewModel.pendingRequestCount) {
                        showFriendRequest = true
                    }

                    // 검색바
                    HStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16))
                                .foregroundColor(.customGray300)

                            TextField("검색", text: $viewModel.searchText)
                                .font(.system(size: 15))
                                .foregroundColor(.textWhite)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(white: 0.4), lineWidth: 0.5))

                        Button {
                            viewModel.searchText = ""
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textWhite)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().stroke(Color(white: 0.4), lineWidth: 0.5))
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 30)

                    // MARK: 친구 리스트
                    if viewModel.isLoading || viewModel.isSearching {
                        ScrollView {
                            FriendSkeletonList()
                        }
                    } else if viewModel.filteredFriends.isEmpty {
                        Spacer()
                        VStack(spacing: 24) {
                            Image("Crying_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                            Text(viewModel.searchText.isEmpty ? "추천 친구가 없습니다" : "검색 결과가 없습니다")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.customGray300)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                // 검색 중이 아닐 때만 "추천 친구" 타이틀
                                if isRefreshing {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.bottom, 8)
                                }

                                if viewModel.searchText.isEmpty {
                                    Text("추천 친구")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.textWhite)
                                        .padding(.horizontal, 22)
                                        .padding(.bottom, 12)
                                }

                                ForEach(viewModel.filteredFriends) { friend in
                                    SuggestedFriendRow(
                                        friend: friend,
                                        onAdd: { viewModel.sendRequest(to: friend) },
                                        onCancel: { viewModel.cancelRequest(to: friend) },
                                        onHide: { withAnimation(.easeInOut(duration: 0.3)) { viewModel.hideFriend(friend) } },
                                        onStatusCheck: { handle in viewModel.refreshRequestStatus(handle: handle) }
                                    )
                                    .transition(.opacity.combined(with: .offset(x: -50)))
                                }
                            }
                            .padding(.top, 4)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                                            if newValue > 250 && !isRefreshing {
                                                isRefreshing = true
                                                Task {
                                                    await viewModel.loadRecommendedFriends()
                                                    try? await Task.sleep(nanoseconds: 500_000_000)
                                                    isRefreshing = false
                                                }
                                            }
                                        }
                                }
                            )
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.loadRecommendedFriends()
            }
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.onSearchTextChanged()
            }
            .navigationDestination(isPresented: $showFriendRequest) {
                FriendRequestView()
            }
        }
    }
}

struct FriendView_Previews: PreviewProvider {
    static var previews: some View {
        FriendView()
    }
}
