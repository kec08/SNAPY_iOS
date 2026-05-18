//
//  LikeListSheet.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/18/26.
//

import SwiftUI
import Kingfisher

struct LikeListSheet: View {
    let albumId: Int
    @State private var likeUsers: [AlbumLikeUserData] = []
    @State private var isLoading = true
    @State private var myFriends: Set<String> = []
    @State private var requestedHandles: Set<String> = []
    @State private var selectedUser: AlbumLikeUserData? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("좋아요")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textWhite)
                .padding(.top, 20)
                .padding(.bottom, 16)

            if isLoading {
                Spacer()
                ProgressView().tint(.white)
                Spacer()
            } else if likeUsers.isEmpty {
                Spacer()
                Text("아직 좋아요가 없습니다")
                    .font(.system(size: 15))
                    .foregroundColor(.customGray300)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(likeUsers) { user in
                            likeRow(user: user)
                        }
                    }
                }
            }
        }
        .task {
            await loadData()
        }
        .fullScreenCover(item: $selectedUser) { user in
            NavigationStack {
                FriendProfileView(
                    name: user.username,
                    handle: user.handle,
                    profileImageUrl: user.profileImageUrl
                )
            }
        }
    }

    // MARK: - 좋아요 Row

    @ViewBuilder
    private func likeRow(user: AlbumLikeUserData) -> some View {
        let isFriend = myFriends.contains(user.handle)
        let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""
        let isMe = user.handle == myHandle

        Button {
            if isMe {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: .switchToProfileTab, object: nil)
                }
            } else {
                selectedUser = user
            }
        } label: {
            HStack(spacing: 12) {
                if let url = user.profileImageUrl, let imgUrl = URL(string: url) {
                    KFImage(imgUrl)
                        .resizable()
                        .placeholder { Image("Profile_img").resizable().scaledToFill() }
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image("Profile_img")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(user.username)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textWhite)
                    Text("@\(user.handle)")
                        .font(.system(size: 13))
                        .foregroundColor(.customGray300)
                }

                Spacer()

                if isMe {
                    Text("나")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.customGray300)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.customDarkGray)
                        .cornerRadius(6)
                } else {
                    if isFriend {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12))
                            Text("친구")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.MainYellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.customDarkGray)
                        .cornerRadius(6)
                    } else if requestedHandles.contains(user.handle) {
                        Text("요청됨")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.customGray300)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.customDarkGray)
                            .cornerRadius(6)
                    } else {
                        Button {
                            Task {
                                do {
                                    try await FriendService.shared.sendRequest(handle: user.handle)
                                    requestedHandles.insert(user.handle)
                                } catch {
                                    requestedHandles.insert(user.handle)
                                }
                            }
                        } label: {
                            Text("친구 추가")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textWhite)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.customDarkGray)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 데이터 로드

    private func loadData() async {
        let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""

        async let likesTask: [AlbumLikeUserData] = {
            (try? await AlbumService.shared.fetchLikes(albumId: albumId)) ?? []
        }()
        async let friendsTask: [FriendData] = {
            (try? await FriendService.shared.getFriends(handle: myHandle)) ?? []
        }()

        let likes = await likesTask
        let friends = await friendsTask

        likeUsers = likes.sorted { ($0.likedAt ?? "") > ($1.likedAt ?? "") }
        myFriends = Set(friends.map { $0.handle })
        isLoading = false
    }
}
