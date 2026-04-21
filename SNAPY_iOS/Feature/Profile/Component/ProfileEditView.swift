//
//  ProfileEditView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct ProfileEditView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // 프로필 이미지 변경
                    VStack(spacing: 8) {
                        PhotosPicker(selection: $viewModel.profilePickerItem, matching: .images) {
                            Group {
                                if let profileImage = viewModel.profileImage {
                                    Image(uiImage: profileImage)
                                        .resizable()
                                        .scaledToFill()
                                } else if let url = viewModel.profileImageUrl, let imgUrl = URL(string: url) {
                                    KFImage(imgUrl)
                                        .resizable()
                                        .placeholder { Color.customDarkGray.overlay(ProgressView().tint(.white)) }
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
                            .overlay(
                                Circle().stroke(Color(white: 0.3), lineWidth: 1)
                            )
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.mainYellow)
                                    .clipShape(Circle())
                            }
                        }
                        .onChange(of: viewModel.profilePickerItem) { _, _ in
                            Task { await viewModel.loadProfileImage() }
                        }

                        Text("프로필 사진 변경")
                            .padding(.top, 8)
                            .font(.system(size: 13))
                            .foregroundColor(.mainYellow)
                    }
                    .padding(.top, 12)

                    // 배너 이미지 변경
                    VStack(spacing: 8) {
                        PhotosPicker(selection: $viewModel.bannerPickerItem, matching: .images) {
                            Group {
                                if let bannerImage = viewModel.bannerImage {
                                    Image(uiImage: bannerImage)
                                        .resizable()
                                        .scaledToFill()
                                } else if let url = viewModel.bannerImageUrl, let imgUrl = URL(string: url) {
                                    KFImage(imgUrl)
                                        .resizable()
                                        .placeholder { Color.customDarkGray.overlay(ProgressView().tint(.white)) }
                                        .fade(duration: 0.2)
                                        .scaledToFill()
                                } else {
                                    Image("Banner_img")
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(12)
                        }
                        .onChange(of: viewModel.bannerPickerItem) { _, _ in
                            Task { await viewModel.loadBannerImage() }
                        }

                        Text("배너 이미지 변경")
                            .padding(.top, 8)
                            .font(.system(size: 13))
                            .foregroundColor(.mainYellow)
                    }

                    // 이름 수정
                    VStack(alignment: .leading, spacing: 8) {
                        Text("이름")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.customGray300)
                        TextField("이름을 입력해주세요", text: $viewModel.editUsername)
                            .font(.system(size: 17))
                            .foregroundColor(.textWhite)
                            .padding(.bottom, 8)
                        Rectangle()
                            .fill(viewModel.editUsername.isEmpty ? Color(white: 0.3) : Color.mainYellow)
                            .frame(height: 1.5)
                    }

                    // 사용자 ID 수정
                    VStack(alignment: .leading, spacing: 8) {
                        Text("사용자 ID")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.customGray300)
                        TextField("사용자 ID를 입력해주세요", text: $viewModel.editHandle)
                            .font(.system(size: 17))
                            .foregroundColor(.textWhite)
                            .textInputAutocapitalization(.never)
                            .padding(.bottom, 8)
                        Rectangle()
                            .fill(viewModel.editHandle.isEmpty ? Color(white: 0.3) : Color.mainYellow)
                            .frame(height: 1.5)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .navigationTitle("프로필 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("저장") {
                    viewModel.saveEdit()
                    dismiss()
                }
                .foregroundColor(.mainYellow)
                .disabled(viewModel.editUsername.isEmpty || viewModel.editHandle.isEmpty)
            }
        }
    }
}
