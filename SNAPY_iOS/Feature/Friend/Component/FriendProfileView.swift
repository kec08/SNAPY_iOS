//
//  FriendProfileView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI

struct FriendProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let name: String
    let handle: String
    let profileImageUrl: String?
    var isFriend: Bool = false
    var mutualFriendsText: String? = nil     // "김은찬 외 4명과 친구"
    var contactText: String? = nil            // "연락처에 있는 친구"

    // 목 데이터
    private let postCount = 5
    private let friendCount = 13
    private let streakCount = 2

    @State private var isFriendRequested = false
    @State private var showFriendSheet = false
    @State private var currentFriend: Bool

    init(name: String, handle: String, profileImageUrl: String?, isFriend: Bool = false, mutualFriendsText: String? = nil, contactText: String? = nil) {
        self.name = name
        self.handle = handle
        self.profileImageUrl = profileImageUrl
        self.isFriend = isFriend
        self.mutualFriendsText = mutualFriendsText
        self.contactText = contactText
        self._currentFriend = State(initialValue: isFriend)
    }

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: 배너
                    Color.customDarkGray
                        .frame(height: 200)

                    // MARK: 프로필 정보
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center) {
                            Group {
                                if let url = profileImageUrl {
                                    AsyncImage(url: URL(string: url)) { phase in
                                        switch phase {
                                        case .success(let img): img.resizable().scaledToFill()
                                        default: Color.customDarkGray
                                        }
                                    }
                                } else {
                                    Image("Profile_img")
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.backgroundBlack, lineWidth: 3))

                            Spacer().frame(width: 30)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.textWhite)

                                HStack(spacing: 65) {
                                    statItem(value: postCount, label: "게시물")
                                    statItem(value: friendCount, label: "친구")

                                    VStack(spacing: 6) {
                                        Image("Strick_fire")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 26)
                                        Text("\(streakCount)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.textWhite)
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                            .padding(.top, 10)
                        }

                        // 겹친구 (친구인 경우) / 연락처 친구 (비친구인 경우)
                        if currentFriend {
                            if let mutual = mutualFriendsText {
                                Text(mutual)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.textWhite)
                            }
                        } else {
                            if let contact = contactText {
                                Text(contact)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.customGray300)
                            }
                        }

                        // @handle
                        Text("@\(handle)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textWhite)

                        // MARK: 버튼 영역 (친구 / 비친구 분기)
                        if currentFriend {
                            // 친구인 경우: [친구] + [방명록 작성]
                            HStack(spacing: 12) {
                                Button {
                                    showFriendSheet = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.2.fill")
                                            .font(.system(size: 13))
                                        Text("친구")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .foregroundColor(.mainYellow)
                                    .background(.customDarkGray)
                                    .cornerRadius(8)
                                }

                                Button {
                                    // 방명록 작성 (추후 연결)
                                } label: {
                                    Text("방명록 작성")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .foregroundColor(.textWhite)
                                        .background(.customDarkGray)
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            // 비친구: [친구 추가] / [요청됨]
                            Button {
                                isFriendRequested.toggle()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: isFriendRequested ? "clock" : "person.badge.plus")
                                        .font(.system(size: 14, weight: .medium))
                                    Text(isFriendRequested ? "요청됨" : "친구 추가")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .foregroundColor(isFriendRequested ? .customGray300 : .textWhite)
                                .background(.customDarkGray)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 22)

                    // MARK: 하단 콘텐츠 (친구 / 비친구 분기)
                    if currentFriend {
                        // 친구인 경우: 방명록 + 피드
                        VStack(spacing: 20) {
                            // 방명록 (목 데이터)
                            GuestbookSection(viewModel: ProfileViewModel())
                                .padding(.top, 20)

                            Divider()
                                .background(Color.Gray500)
                                .padding(.horizontal, 22)

                            // 피드 (목 데이터)
                            ProfileFeedGrid(posts: [
                                FeedPost(thumbnailImage: "Mock_img1", images: ["Mock_img1"], date: "2026.04.01"),
                                FeedPost(thumbnailImage: "Mock_img2", images: ["Mock_img2"], date: "2026.03.28"),
                                FeedPost(thumbnailImage: "Mock_img3", images: ["Mock_img3"], date: "2026.03.25"),
                                FeedPost(thumbnailImage: "Mock_img4", images: ["Mock_img4"], date: "2026.03.20"),
                            ])
                        }
                    } else {
                        // 비친구: 공개 프로필 안내
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.textWhite)
                                .padding(.bottom, 8)

                            Text("친구 공개 프로필입니다")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.textWhite)

                            Text("지금 친구 추가하고 친구의 SNAP을 만나보세요.")
                                .font(.system(size: 14))
                                .foregroundColor(.customGray300)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textWhite)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: "SNAPY 프로필: @\(handle)\nhttps://snapy.app/@\(handle)") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textWhite)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .toolbarBackground(Color.clear, for: .navigationBar)
        .sheet(isPresented: $showFriendSheet) {
            FriendRelationSheet(
                name: name,
                handle: handle,
                onRemoveFriend: {
                    showFriendSheet = false
                    dismiss()
                }
            )
            .presentationDetents([.fraction(0.35)])
            .presentationDragIndicator(.visible)
        }
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.customGray300)
            Text("\(value)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textWhite)
        }
    }
}

// MARK: - Preview

#Preview("공개 프로필 (비친구)") {
    NavigationStack {
        FriendProfileView(
            name: "김무기",
            handle: "david_18",
            profileImageUrl: nil,
            isFriend: false,
            contactText: "연락처에 있는 친구"
        )
    }
}

#Preview("친구 프로필") {
    NavigationStack {
        FriendProfileView(
            name: "김무기",
            handle: "david_18",
            profileImageUrl: nil,
            isFriend: true,
            mutualFriendsText: "zhvcx_flii, kimikhnа0816님 외 32명 친구 중 입니다"
        )
    }
}
