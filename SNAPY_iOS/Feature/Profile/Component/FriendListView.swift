//
//  FriendListView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/15/26.
//

import SwiftUI
import Kingfisher

struct FriendListView: View {
    @Environment(\.dismiss) private var dismiss

    let handle: String
    @State private var friends: [FriendData] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.white)
            } else if friends.isEmpty {
                VStack(spacing: 12) {
                    Image("Crying_img")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    Text("친구가 없습니다")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.customGray300)
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(friends) { friend in
                            NavigationLink {
                                FriendProfileView(
                                    name: friend.username,
                                    handle: friend.handle,
                                    profileImageUrl: friend.profileImageUrl,
                                    isFriend: true
                                )
                            } label: {
                                FriendListRow(friend: friend)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textWhite)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("친구")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textWhite)
            }
        }
        .toolbarBackground(Color.backgroundBlack, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            do {
                friends = try await FriendService.shared.getFriends(handle: handle)
            } catch {
                print("[FriendList] 로드 실패: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - 친구 행

struct FriendListRow: View {
    let friend: FriendData

    var body: some View {
        HStack(spacing: 14) {
            // 프로필
            if let url = friend.profileImageUrl, let imgUrl = URL(string: url) {
                KFImage(imgUrl)
                    .resizable()
                    .placeholder { Color.customDarkGray }
                    .fade(duration: 0.2)
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            } else {
                Image("Profile_img")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }

            // 이름 + 핸들
            VStack(alignment: .leading, spacing: 3) {
                Text(friend.username)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textWhite)

                Text("@\(friend.handle)")
                    .font(.system(size: 13))
                    .foregroundColor(.customGray300)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.customGray300)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
