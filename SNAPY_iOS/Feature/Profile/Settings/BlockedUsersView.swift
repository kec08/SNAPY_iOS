//
//  BlockedUsersView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/20/26.
//

import SwiftUI
import Kingfisher

struct BlockedUsersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var blockedUsers: [BlockedUserData] = []
    @State private var isLoading = true
    @State private var selectedProfile: BlockedUserData? = nil

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else if blockedUsers.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "nosign")
                            .font(.system(size: 40))
                            .foregroundColor(.customGray300)
                        Text("차단된 사용자가 없습니다")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.customGray300)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(blockedUsers) { user in
                                blockedUserRow(user: user)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 && abs(value.translation.height) < 100 {
                        dismiss()
                    }
                }
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textWhite)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("차단된 사용자")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textWhite)
            }
        }
        .toolbarBackground(Color.backgroundBlack, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadBlockedUsers()
        }
        .navigationDestination(item: $selectedProfile) { user in
            FriendProfileView(
                name: user.username,
                handle: user.handle,
                profileImageUrl: user.profileImageUrl
            )
        }
    }

    // MARK: - 차단 유저 행

    @ViewBuilder
    private func blockedUserRow(user: BlockedUserData) -> some View {
        HStack(spacing: 14) {
            // 프로필 탭 → 프로필로 이동
            Button {
                selectedProfile = user
            } label: {
                HStack(spacing: 14) {
                    if let url = user.profileImageUrl, let imgUrl = URL(string: url) {
                        KFImage(imgUrl)
                            .resizable()
                            .placeholder { Image("Profile_img").resizable().scaledToFill() }
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Image("Profile_img")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.username)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.textWhite)
                        Text("@\(user.handle)")
                            .font(.system(size: 13))
                            .foregroundColor(.customGray300)
                    }
                }
            }

            Spacer()

            // 차단 해제 버튼
            Button {
                Task { await unblock(user: user) }
            } label: {
                Text("해제")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.backgroundBlack)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.mainYellow)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - API

    private func loadBlockedUsers() async {
        isLoading = true
        do {
            blockedUsers = try await BlockService.shared.getBlockedUsers()
        } catch {
            print("[BlockedUsersView] 로드 실패: \(error)")
        }
        isLoading = false
    }

    private func unblock(user: BlockedUserData) async {
        do {
            try await BlockService.shared.unblockUser(handle: user.handle)
            withAnimation(.easeInOut(duration: 0.3)) {
                blockedUsers.removeAll { $0.id == user.id }
            }
        } catch {
            print("[BlockedUsersView] 차단 해제 실패: \(error)")
        }
    }
}
