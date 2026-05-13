//
//  ProfileHeaderView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel

    @State private var showBannerViewer = false
    @State private var showProfileViewer = false
    @State private var showFriendList = false
    @State private var showStreakSheet = false
    @State private var shareImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 0) {
            // 배너 + 프로필 이미지
            ZStack(alignment: .bottomLeading) {
                // 배너
                Button {
                    showBannerViewer = true
                } label: {
                    if let bannerImage = viewModel.bannerImage {
                        Image(uiImage: bannerImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } else if let url = viewModel.bannerImageUrl, let imgUrl = URL(string: url) {
                        KFImage(imgUrl)
                            .resizable()
                            .placeholder { Color.customDarkGray }
                            .fade(duration: 0.2)
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } else {
                        Color.customDarkGray
                            .frame(height: 200)
                    }
                }
            }

            // 프로필 정보
            VStack(alignment: .leading, spacing: 16) {
                
                HStack(alignment: .center) {
                    // 프로필 이미지
                    Button {
                        showProfileViewer = true
                    } label: {
                        Group {
                            if let profileImage = viewModel.profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                            } else if let url = viewModel.profileImageUrl, let imgUrl = URL(string: url) {
                                KFImage(imgUrl)
                                    .resizable()
                                    .placeholder { Color.customDarkGray }
                                    .fade(duration: 0.2)
                                    .scaledToFill()
                            } else {
                                Color.customDarkGray
                            }
                        }
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.backgroundBlack, lineWidth: 3))
                    }
                    
                    Spacer()
                        .frame(width: 30)
                    
                    // 사용자 이름
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.username)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textWhite)
                        
                        HStack(spacing: 65) {
                            statItem(value: viewModel.postCount, label: "게시물")

                            Button { showFriendList = true } label: {
                                statItem(value: viewModel.friendCount, label: "친구")
                            }
                            
                            Button { showStreakSheet = true } label: {
                                VStack(spacing: 6) {
                                    Image(viewModel.streakCount >= 5 ? "Strick_sequence_fire" : "Strick_fire")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 26)
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

                // 겹지인 목록
                if !viewModel.mutualFriendsText.isEmpty {
                    Text(viewModel.mutualFriendsText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textWhite)
                }

                // 사용자 id
                Text("@\(viewModel.handle)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textWhite)

                HStack(spacing: 12) {
                    Button {
                        viewModel.startEdit()
                    } label: {
                        Text("프로필 수정")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(.customDarkGray)
                            .foregroundColor(.textWhite)
                            .cornerRadius(8)
                    }

                    Button {
                        shareProfile()
                    } label: {
                        Text("프로필 공유")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(.customDarkGray)
                            .foregroundColor(.textWhite)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.top, 48)
            .padding(.horizontal, 20)
        }
        // 배너 확대 보기
        .fullScreenCover(isPresented: $showBannerViewer) {
            ImageViewerView(
                image: viewModel.bannerImage,
                imageUrl: viewModel.bannerImageUrl,
                assetName: "Banner_img",
                isCircle: false
            )
        }
        // 프로필 확대 보기
        .fullScreenCover(isPresented: $showProfileViewer) {
            ImageViewerView(
                image: viewModel.profileImage,
                imageUrl: viewModel.profileImageUrl,
                assetName: "Profile_img",
                isCircle: true
            )
        }
        .navigationDestination(isPresented: $showFriendList) {
            FriendListView(handle: viewModel.handle)
        }
        .sheet(isPresented: $showStreakSheet) {
            StreakSheet(
                currentStreak: viewModel.streakCount,
                maxStreak: viewModel.maxStreak
            )
            .presentationDetents([.fraction(0.3)])
            .presentationDragIndicator(.visible)
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
    }

    private func shareProfile() {
        Task {
            async let bannerImg = downloadImage(from: viewModel.bannerImageUrl)
            async let profileImg = downloadImage(from: viewModel.profileImageUrl)

            let card = ProfileShareCard(
                bannerImage: await bannerImg,
                profileImage: await profileImg,
                username: viewModel.username,
                handle: viewModel.handle,
                postCount: viewModel.postCount,
                friendCount: viewModel.friendCount,
                streakCount: viewModel.streakCount
            )
            if let image = renderShareImage(card) {
                shareImage = image
            }
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

// MARK: - 스트릭 시트

struct StreakSheet: View {
    let currentStreak: Int
    let maxStreak: Int

    var body: some View {
        VStack(spacing: 50) {
            Spacer().frame(height: 10)

            Text("스트릭")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textWhite)

            HStack(spacing: -20) {
                // 현재 스트릭
                VStack(spacing: 16) {
                    Text("현재 스트릭")
                        .font(.system(size: 15))
                        .foregroundColor(.customGray300)
                    HStack(spacing: 10) {
                        Image(currentStreak >= 5 ? "Strick_sequence_fire" : "Strick_fire")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 42)
                        Text("\(currentStreak)일")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.textWhite)
                    }
                }
                .frame(maxWidth: .infinity)

                // 최대 스트릭
                VStack(spacing: 16) {
                    Text("최대 스트릭")
                        .font(.system(size: 15))
                        .foregroundColor(.customGray300)
                    HStack(spacing: 10) {
                        Image(maxStreak >= 5 ? "Strick_sequence_fire" : "Strick_fire")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 42)
                        Text("\(maxStreak)일")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.textWhite)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScrollView {
        ProfileHeaderView(viewModel: {
            let vm = ProfileViewModel()
            vm.username = "김은찬"
            vm.handle = "eunchan"
            vm.postCount = 42
            vm.friendCount = 128
            vm.streakCount = 7
            vm.mutualFriendsText = "zhnzx.8님, kimkihak08님 외 32명 친구 중 입니다"
            return vm
        }())
    }
    .background(Color.backgroundBlack)
}
