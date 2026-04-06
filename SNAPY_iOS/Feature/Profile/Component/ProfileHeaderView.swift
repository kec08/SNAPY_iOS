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

    var body: some View {
        VStack(spacing: 0) {
            // 배너 이미지
            ZStack(alignment: .bottomLeading) {
                // 배너
                PhotosPicker(selection: $viewModel.bannerPickerItem, matching: .images) {
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
                .onChange(of: viewModel.bannerPickerItem) { _, _ in
                    Task { await viewModel.loadBannerImage() }
                }

                // 프로필 이미지 (배너 위에 겹침)
                PhotosPicker(selection: $viewModel.profilePickerItem, matching: .images) {
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
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.backgroundBlack, lineWidth: 3))
                }
                .offset(x: 16, y: 40)
                .onChange(of: viewModel.profilePickerItem) { _, _ in
                    Task { await viewModel.loadProfileImage() }
                }
            }

            // 프로필 정보
            VStack(alignment: .leading, spacing: 8) {
                // 이름 + 통계
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.username)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.textWhite)
                    }

                    Spacer()

                    // 게시물 / 친구 / 스트릭
                    HStack(spacing: 20) {
                        statItem(value: viewModel.postCount, label: "게시물")
                        statItem(value: viewModel.friendCount, label: "친구")

                        // 스트릭 (불꽃 아이콘)
                        VStack(spacing: 2) {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                Text("\(viewModel.streakCount)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.textWhite)
                            }
                        }
                    }
                }

                // 겹치는 친구
                Text(viewModel.mutualFriendsText)
                    .font(.system(size: 12))
                    .foregroundColor(.customGray300)
                    .lineLimit(1)

                // 핸들
                Text("@\(viewModel.handle)")
                    .font(.system(size: 14))
                    .foregroundColor(.customGray300)

                // 버튼 영역
                HStack(spacing: 12) {
                    Button {
                        viewModel.startEdit()
                    } label: {
                        Text("프로필 수정")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color(white: 0.2))
                            .foregroundColor(.textWhite)
                            .cornerRadius(8)
                    }

                    ShareLink(item: "SNAPY 프로필: @\(viewModel.handle)\nhttps://snapy.app/@\(viewModel.handle)") {
                        Text("프로필 공유")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color(white: 0.2))
                            .foregroundColor(.textWhite)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.top, 48)
            .padding(.horizontal, 16)
        }
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textWhite)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.customGray300)
        }
    }
}
