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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    FriendHeaderView {
                        showFriendRequest = true
                    }

                    // 검색바 (글래스) + X 분리
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
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textWhite)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().stroke(Color(white: 0.4), lineWidth: 0.5))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    // MARK: 추천 친구 리스트
                    if viewModel.filteredFriends.isEmpty {
                        Spacer()
                        Text("추천 친구가 없습니다")
                            .font(.system(size: 14))
                            .foregroundColor(.customGray300)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("추천 친구")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.customGray300)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 12)

                                ForEach(viewModel.filteredFriends) { friend in
                                    SuggestedFriendRow(
                                        friend: friend,
                                        onAdd: { viewModel.sendRequest(to: friend) },
                                        onCancel: { viewModel.cancelRequest(to: friend) },
                                        onHide: { viewModel.hideFriend(friend) }
                                    )
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct FriendView_Previews: PreviewProvider {
    static var previews: some View {
        FriendView()
    }
}
