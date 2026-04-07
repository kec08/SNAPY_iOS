//
//  ProfileHeaderView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import PhotosUI

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel

    @State private var showBannerViewer = false
    @State private var showProfileViewer = false

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
                            .frame(height: 160)
                            .clipped()
                    } else {
                        Image("Banner_img")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
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
                    
                    Spacer()
                        .frame(width: 30)
                    
                    // 사용자 이름
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.username)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textWhite)
                        
                        HStack(spacing: 65) {
                            statItem(value: viewModel.postCount, label: "게시물")
                            statItem(value: viewModel.friendCount, label: "친구")
                            
                            VStack(spacing: 6) {
                                Image("Strick_fire")
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

                // 겹지인 목록
                Text(viewModel.mutualFriendsText)
                    .font(.system(size: 12))
                    .foregroundColor(.textWhite)
                    .lineLimit(1)

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
                            .background(.darkGray)
                            .foregroundColor(.textWhite)
                            .cornerRadius(8)
                    }

                    ShareLink(item: "SNAPY 프로필: @\(viewModel.handle)\nhttps://snapy.app/@\(viewModel.handle)") {
                        Text("프로필 공유")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(.darkGray)
                            .foregroundColor(.textWhite)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.top, 48)
            .padding(.horizontal, 16)
        }
        // 배너 확대 보기
        .fullScreenCover(isPresented: $showBannerViewer) {
            ImageViewerView(
                image: viewModel.bannerImage,
                assetName: "Banner_img"
            )
        }
        // 프로필 확대 보기
        .fullScreenCover(isPresented: $showProfileViewer) {
            ImageViewerView(
                image: viewModel.profileImage,
                assetName: "Profile_img"
            )
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
