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
    @StateObject private var viewModel: FriendProfileViewModel
    @StateObject private var guestbookVM = ProfileViewModel()

    @State private var showFriendSheet = false
    @State private var showBannerViewer = false
    @State private var showProfileViewer = false
    @State private var showFriendList = false
    @State private var showStreakSheet = false
    @State private var showStory = false
    @State private var isRefreshing = false
    @State private var shareImage: UIImage? = nil
    @State private var showReportSheet = false
    @State private var showBlockAlert = false
    @State private var showMoreMenu = false

    init(name: String, handle: String, profileImageUrl: String?,
         bannerImageUrl: String? = nil, isFriend: Bool = false,
         mutualFriendsText: String? = nil, contactText: String? = nil) {
        _viewModel = StateObject(wrappedValue: FriendProfileViewModel(
            name: name, handle: handle, profileImageUrl: profileImageUrl,
            bannerImageUrl: bannerImageUrl, isFriend: isFriend,
            mutualFriendsText: mutualFriendsText, contactText: contactText
        ))
    }

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    if isRefreshing {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 60)
                            .padding(.bottom, 10)
                            .zIndex(1)
                    }

                    // MARK: 배너
                    Button { UIImpactFeedbackGenerator(style: .light).impactOccurred(); showBannerViewer = true } label: {
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .overlay(
                                Group {
                                    if let url = viewModel.bannerImageUrl, let imgUrl = URL(string: url) {
                                        KFImage(imgUrl)
                                            .resizable()
                                            .placeholder { Image("Banner_img").resizable().scaledToFill() }
                                            .fade(duration: 0.2)
                                            .scaledToFill()
                                    } else {
                                        Image("Banner_img")
                                            .resizable()
                                            .scaledToFill()
                                    }
                                }
                            )
                            .clipShape(Rectangle())
                    }

                    // MARK: 프로필 정보
                    profileInfoSection

                    // MARK: 하단 콘텐츠
                    if viewModel.currentFriend {
                        friendContentSection
                    } else if !viewModel.isLoading {
                        nonFriendSection
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                                if newValue > 140 && !isRefreshing {
                                    isRefreshing = true
                                    Task {
                                        await viewModel.refresh()
                                        guestbookVM.handle = viewModel.handle
                                        await guestbookVM.loadGuestbook()
                                        try? await Task.sleep(nanoseconds: 500_000_000)
                                        isRefreshing = false
                                    }
                                }
                            }
                    }
                )
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
        .safeAreaInset(edge: .top) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }
                .buttonStyle(.glass)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        Task {
                            if let image = await viewModel.shareProfile() {
                                shareImage = image
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.primary)
                    }
                    .buttonStyle(.glass)

                    Menu {
                        Button(role: .destructive) {
                            showReportSheet = true
                        } label: {
                            Label("신고", systemImage: "exclamationmark.triangle")
                        }

                        Button(role: .destructive) {
                            showBlockAlert = true
                        } label: {
                            Label("차단", systemImage: "nosign")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.primary)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.glass)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .background(Color.clear)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guestbookVM.handle = viewModel.handle
            async let loadTask: () = viewModel.loadAll()
            async let guestbookTask: () = guestbookVM.loadGuestbook()
            _ = await (loadTask, guestbookTask)
        }
        .sheet(isPresented: $showFriendSheet) {
            FriendRelationSheet(
                name: viewModel.name,
                handle: viewModel.handle,
                onRemoveFriend: {
                    Task {
                        do { try await FriendService.shared.removeFriend(handle: viewModel.handle) }
                        catch { print("[FriendProfile] 친구 삭제 실패: \(error)") }
                    }
                    showFriendSheet = false
                    dismiss()
                }
            )
            .presentationDetents([.fraction(0.35)])
            .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $showFriendList) {
            FriendListView(handle: viewModel.handle)
        }
        .sheet(isPresented: $showStreakSheet) {
            StreakSheet(currentStreak: viewModel.streakCount, maxStreak: viewModel.maxStreak)
                .presentationDetents([.fraction(0.3)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showBannerViewer) {
            ImageViewerView(image: nil, imageUrl: viewModel.bannerImageUrl, assetName: "Banner_img", isCircle: false)
        }
        .fullScreenCover(isPresented: $showProfileViewer) {
            ImageViewerView(image: nil, imageUrl: viewModel.profileImageUrl, assetName: "Profile_img", isCircle: true)
        }
        .sheet(isPresented: Binding(
            get: { shareImage != nil },
            set: { if !$0 { shareImage = nil } }
        )) {
            if let image = shareImage {
                let text = "SNAPY 프로필: @\(viewModel.handle)\n\nSNAPY에서 당신의 일상을 공유해보세요!"
                ShareSheetView(items: [image, text])
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportView(reportType: .USER, targetId: viewModel.handle)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .alert("이 사용자를 차단하시겠습니까?", isPresented: $showBlockAlert) {
            Button("취소", role: .cancel) { }
            Button("차단", role: .destructive) {
                print("[Block] 차단: \(viewModel.handle)")
            }
        } message: {
            Text("차단하면 상대방의 게시물, 스토리가 표시되지 않으며 상대방도 내 콘텐츠를 볼 수 없습니다.")
        }
        .fullScreenCover(isPresented: $showStory) {
            if let story = viewModel.friendStory {
                StoryDetailView(stories: [story], initialIndex: 0)
            }
        }
    }

    // MARK: - 프로필 정보

    @ViewBuilder
    private var profileInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            profileImageAndStats

            if !viewModel.currentFriend {
                if let mutual = viewModel.mutualFriendsText {
                    Text(mutual)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textWhite)
                } else if let contact = viewModel.contactText {
                    Text(contact)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.customGray300)
                }
            }

            Text("@\(viewModel.handle)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textWhite)

            if viewModel.isLoading {
                // 로딩 중에는 버튼 숨김
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.customDarkGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            } else if viewModel.currentFriend {
                friendButton
            } else {
                friendRequestButton
            }
        }
        .padding(.top, 28)
        .padding(.horizontal, 22)
    }

    // MARK: - 프로필 이미지 + 통계

    @ViewBuilder
    private var profileImageAndStats: some View {
        HStack(alignment: .center) {
            Group {
                if let url = viewModel.profileImageUrl, let imgUrl = URL(string: url) {
                    KFImage(imgUrl)
                        .resizable()
                        .placeholder { Image("Profile_img").resizable().scaledToFill() }
                        .fade(duration: 0.2)
                        .scaledToFill()
                } else {
                    Image("Profile_img").resizable().scaledToFill()
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .padding(5)
            .overlay(storyRingOverlay)
            .onTapGesture {
                if let story = viewModel.friendStory {
                    showStory = true
                    SeenStoryStore.markSeen(story.storyIds)
                }
            }
            .onLongPressGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showProfileViewer = true
            }

            Spacer().frame(width: 30)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textWhite)

                HStack(spacing: 65) {
                    statItem(value: viewModel.postCount, label: "게시물")
                    Button { showFriendList = true } label: { statItem(value: viewModel.friendCount, label: "친구") }
                    Button { showStreakSheet = true } label: {
                        VStack(spacing: 6) {
                            Image(viewModel.streakCount >= 5 ? "Strick_sequence_fire" : "Strick_fire")
                                .resizable().scaledToFit().frame(height: 26)
                            Text("\(viewModel.streakCount)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.textWhite)
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
            .padding(.top, 10)
        }
    }

    @ViewBuilder
    private var storyRingOverlay: some View {
        if let story = viewModel.friendStory {
            Circle()
                .stroke(
                    story.storyIds.allSatisfy({ SeenStoryStore.isSeen($0) })
                        ? AnyShapeStyle(Color.customGray500)
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color(hex: "FFC83D"), Color(hex: "FF9F1C")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )),
                    lineWidth: 2.5
                )
        }
    }

    // MARK: - 버튼들

    private var friendButton: some View {
        Button { showFriendSheet = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill").font(.system(size: 13))
                Text("친구").font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity).frame(height: 36)
            .foregroundColor(.mainYellow)
            .background(.customDarkGray).cornerRadius(8)
        }
    }

    private var friendRequestButton: some View {
        Button { viewModel.toggleFriendRequest() } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.isFriendRequested ? "clock" : "person.badge.plus")
                    .font(.system(size: 14, weight: .medium))
                Text(viewModel.isFriendRequested ? "요청 대기중" : "친구 추가")
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity).frame(height: 40)
            .foregroundColor(viewModel.isFriendRequested ? .customGray300 : .textWhite)
            .background(.customDarkGray).cornerRadius(8)
        }
    }

    // MARK: - 친구 콘텐츠

    @ViewBuilder
    private var friendContentSection: some View {
        VStack(spacing: 20) {
            GuestbookSection(viewModel: guestbookVM, isMyProfile: false)
                .padding(.top, 20)

            Divider().background(Color.Gray500).padding(.horizontal, 22)

            if viewModel.isLoading {
                ProfileFeedSkeletonGrid()
            } else if viewModel.feedPosts.isEmpty {
                Text("이번달에 올린 게시물이 없습니다")
                    .font(.system(size: 16))
                    .foregroundColor(.customGray300)
                    .padding(.top, 40)
            } else {
                ProfileFeedGrid(
                    posts: viewModel.feedPosts,
                    displayName: viewModel.name,
                    handle: viewModel.handle,
                    profileImageUrl: viewModel.profileImageUrl
                )
            }
        }
    }

    // MARK: - 비친구 안내

    @ViewBuilder
    private var nonFriendSection: some View {
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

    // MARK: - 통계 아이템

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Text(label).font(.system(size: 12)).foregroundColor(.customGray300)
            Text("\(value)").font(.system(size: 18, weight: .bold)).foregroundColor(.textWhite)
        }
    }
}

// MARK: - Preview

#Preview("공개 프로필 (비친구)") {
    NavigationStack {
        FriendProfileView(name: "김무기", handle: "david_18", profileImageUrl: nil, isFriend: false)
    }
}

#Preview("친구 프로필") {
    NavigationStack {
        FriendProfileView(name: "김무기", handle: "david_18", profileImageUrl: nil, isFriend: true)
    }
}
