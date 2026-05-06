//
//  FriendProfileView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI
import Kingfisher

struct FriendProfileView: View {
    @Environment(\.dismiss) private var dismiss

    let handle: String
    var isFriend: Bool = false
    var initialMutualFriendsText: String? = nil
    var initialContactText: String? = nil

    // 서버에서 로드되는 값
    @State private var name: String
    @State private var profileImageUrl: String?
    @State private var bannerImageUrl: String?
    @State private var friendCount: Int = 0
    @State private var postCount: Int = 0
    @State private var streakCount: Int = 0
    @State private var isLoading = true
    @State private var mutualFriendsText: String?
    @State private var contactText: String?

    @State private var feedPosts: [FeedPost] = []

    @State private var isFriendRequested = false
    @State private var showFriendSheet = false
    @State private var currentFriend: Bool
    @State private var showBannerViewer = false
    @State private var showProfileViewer = false
    @StateObject private var guestbookVM = ProfileViewModel()

    init(name: String, handle: String, profileImageUrl: String?, bannerImageUrl: String? = nil, isFriend: Bool = false, mutualFriendsText: String? = nil, contactText: String? = nil) {
        self.handle = handle
        self.isFriend = isFriend
        self.initialMutualFriendsText = mutualFriendsText
        self.initialContactText = contactText
        self._name = State(initialValue: name)
        self._profileImageUrl = State(initialValue: profileImageUrl)
        self._bannerImageUrl = State(initialValue: bannerImageUrl)
        self._currentFriend = State(initialValue: isFriend)
        self._mutualFriendsText = State(initialValue: mutualFriendsText)
        self._contactText = State(initialValue: contactText)
    }

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: 배너
                    Button { showBannerViewer = true } label: {
                        if let url = bannerImageUrl, let imgUrl = URL(string: url) {
                            KFImage(imgUrl)
                                .resizable()
                                .placeholder { Image("Banner_img").resizable().scaledToFill() }
                                .fade(duration: 0.2)
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        } else {
                            Image("Banner_img")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        }
                    }

                    // MARK: 프로필 정보
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center) {
                            Button { showProfileViewer = true } label: {
                                Group {
                                    if let url = profileImageUrl, let imgUrl = URL(string: url) {
                                        KFImage(imgUrl)
                                            .resizable()
                                            .placeholder { Image("Profile_img").resizable().scaledToFill() }
                                            .fade(duration: 0.2)
                                            .scaledToFill()
                                    } else {
                                        Image("Profile_img")
                                            .resizable()
                                            .scaledToFill()
                                    }
                                }
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.backgroundBlack, lineWidth: 3))
                            }

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

                        // 겹친구 > 연락처 우선순위로 표시
                        if let mutual = mutualFriendsText {
                            Text(mutual)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.textWhite)
                        } else if let contact = contactText {
                            Text(contact)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.customGray300)
                        }

                        // @handle
                        Text("@\(handle)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textWhite)

                        // MARK: 버튼 영역 (친구 / 비친구 분기)
                        if currentFriend {
                            // 친구인 경우: [친구] 버튼만
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
                        } else {
                            // 비친구: [친구 추가] / [요청됨]
                            Button {
                                if isFriendRequested {
                                    isFriendRequested = false
                                    Task {
                                        do { try await FriendService.shared.cancelRequest(handle: handle) }
                                        catch { isFriendRequested = true }
                                    }
                                } else {
                                    isFriendRequested = true
                                    Task {
                                        do { try await FriendService.shared.sendRequest(handle: handle) }
                                        catch { isFriendRequested = false }
                                    }
                                }
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
                            GuestbookSection(viewModel: guestbookVM, isMyProfile: false)
                                .padding(.top, 20)

                            Divider()
                                .background(Color.Gray500)
                                .padding(.horizontal, 22)

                            // 피드 (서버 데이터)
                            if feedPosts.isEmpty && !isLoading {
                                Text("아직 게시물이 없습니다")
                                    .font(.system(size: 14))
                                    .foregroundColor(.customGray300)
                                    .padding(.top, 40)
                            } else {
                                ProfileFeedGrid(
                                    posts: feedPosts,
                                    displayName: name,
                                    handle: handle
                                )
                            }
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
        .task {
            // 서버에서 이 유저의 프로필 + 친구 수 조회
            do {
                let profile = try await ProfileService.shared.fetchUserProfile(handle: handle)
                name = profile.username
                profileImageUrl = profile.profileImageUrl
                bannerImageUrl = profile.backgroundImageUrl
                friendCount = profile.friendCount ?? 0
            } catch {
                print("[FriendProfile] 프로필 로드 실패: \(error)")
            }
            // friendCount가 0이면 친구 목록에서 다시 조회
            if friendCount == 0 {
                do {
                    let friends = try await FriendService.shared.getFriends(handle: handle)
                    friendCount = friends.count
                } catch {
                    print("[FriendProfile] 친구 수 로드 실패: \(error)")
                }
            }
            // 겹친구 조회 (init에서 전달받지 못한 경우 서버에서 조회)
            if mutualFriendsText == nil {
                do {
                    let mutuals = try await FriendService.shared.getMutualFriends(handle: handle)
                    if !mutuals.isEmpty {
                        let firstName = mutuals[0].username
                        if mutuals.count == 1 {
                            mutualFriendsText = "\(firstName)님과 친구입니다"
                        } else {
                            mutualFriendsText = "\(firstName)님 외 \(mutuals.count - 1)명과 친구입니다"
                        }
                    }
                } catch {
                    print("[FriendProfile] 겹친구 로드 실패: \(error)")
                }
                // 연락처 확인 (겹친구가 없을 때)
                if mutualFriendsText == nil && contactText == nil {
                    let contactHandles = Set(UserDefaults.standard.stringArray(forKey: "contactSyncedHandles") ?? [])
                    if contactHandles.contains(handle) {
                        contactText = "연락처에 있음"
                    }
                }
            }
            isLoading = false

            // 방명록 로드 (상대방 handle로)
            guestbookVM.handle = handle
            await guestbookVM.loadGuestbook()

            // 친구인 경우 피드(앨범) 로드
            if currentFriend {
                await loadFriendFeed()
            }
        }
        .sheet(isPresented: $showFriendSheet) {
            FriendRelationSheet(
                name: name,
                handle: handle,
                onRemoveFriend: {
                    Task {
                        do {
                            try await FriendService.shared.removeFriend(handle: handle)
                        } catch {
                            print("[FriendProfile] 친구 삭제 실패: \(error)")
                        }
                    }
                    showFriendSheet = false
                    dismiss()
                }
            )
            .presentationDetents([.fraction(0.35)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showBannerViewer) {
            ImageViewerView(
                image: nil,
                imageUrl: bannerImageUrl,
                assetName: "Banner_img",
                isCircle: false
            )
        }
        .fullScreenCover(isPresented: $showProfileViewer) {
            ImageViewerView(
                image: nil,
                imageUrl: profileImageUrl,
                assetName: "Profile_img",
                isCircle: true
            )
        }
    }

    /// 친구 앨범을 월별로 조회하여 feedPosts에 세팅
    private func loadFriendFeed() async {
        let month = Calendar.current.component(.month, from: Date())
        do {
            let albums = try await AlbumService.shared.fetchAlbumsForUser(month: month, handle: handle)
            let sorted = albums.sorted { $0.albumDate > $1.albumDate }

            let posts: [FeedPost] = await withTaskGroup(of: FeedPost?.self) { group in
                for album in sorted {
                    group.addTask {
                        do {
                            let detail = try await AlbumService.shared.fetchAlbumAsDaily(albumId: album.albumId)
                            guard !detail.photos.isEmpty else { return nil }
                            let thumbnail = detail.photos.first?.backImageUrl ?? ""
                            return FeedPost(
                                id: album.albumId,
                                thumbnailImage: thumbnail,
                                photos: detail.photos,
                                date: album.albumDate.replacingOccurrences(of: "-", with: ".")
                            )
                        } catch {
                            print("[FriendProfile] 앨범 상세 실패 (id=\(album.albumId)): \(error)")
                            return nil
                        }
                    }
                }
                var results: [FeedPost] = []
                for await post in group {
                    if let post { results.append(post) }
                }
                return results.sorted { $0.date > $1.date }
            }

            feedPosts = posts
            postCount = posts.count
            print("[FriendProfile] 피드 \(posts.count)개 로드 완료")
        } catch {
            print("[FriendProfile] 피드 로드 실패: \(error)")
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
