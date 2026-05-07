//
//  RegisterProfileImageView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import SwiftUI

struct RegisterProfileImageView: View {
    var onNext: () -> Void
    var showBackButton: Bool = false
    var onBack: (() -> Void)? = nil

    @State private var profileImage: UIImage?
    @State private var bannerImage: UIImage?
    @State private var showProfilePicker = false
    @State private var showBannerPicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // 헤더
                if showBackButton {
                    SignUpHeader {
                        onBack?()
                    }
                    .padding(.top, 20)
                } else {
                    HStack(spacing: 12) {
                        Image("Login_Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 34)
                        Image("SNAPY_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 130, height: 28)
                    }
                    .padding(.top, 34)
                    .padding(.horizontal, 24)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("프로필을 꾸며보세요")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.textWhite)

                    Text("나중에 설정에서 변경할 수 있습니다")
                        .font(.system(size: 14))
                        .foregroundColor(Color.customGray300)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.horizontal, 24)

                // 배너 이미지
                Button {
                    showBannerPicker = true
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        if let banner = bannerImage {
                            Image(uiImage: banner)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.customDarkGray)
                                .frame(height: 160)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 28))
                                            .foregroundColor(Color.customGray300)
                                        Text("배너 사진 선택")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.customGray300)
                                    }
                                )
                        }
                            

                        Circle()
                            .fill(Color.mainYellow)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.backgroundBlack)
                            )
                            .padding(10)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 16)

                // 프로필 이미지
                Button {
                    showProfilePicker = true
                } label: {
                    ZStack {
                        if let profile = profileImage {
                            Image(uiImage: profile)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.customDarkGray)
                                .frame(width: 120, height: 120)
                                .overlay(
                                    VStack(spacing: 6) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(Color.customGray300)
                                        Text("프로필 사진")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.customGray300)
                                    }
                                )
                        }

                        Circle()
                            .fill(Color.mainYellow)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.backgroundBlack)
                            )
                            .offset(x: 42, y: 42)
                    }
                }
                .padding(.top, 24)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // 건너뛰기 + 다음
                HStack(spacing: 12) {
                    Button {
                        onNext()
                    } label: {
                        Text("건너뛰기")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.customGray300)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    Button {
                        upload()
                    } label: {
                        Text(isLoading ? "업로드 중..." : "다음")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.backgroundBlack)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.textWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                    .disabled(isLoading || (profileImage == nil && bannerImage == nil))
                    .opacity((profileImage != nil || bannerImage != nil) && !isLoading ? 1.0 : 0.4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showProfilePicker) {
            ImagePicker(image: $profileImage, isPresented: $showProfilePicker)
        }
        .sheet(isPresented: $showBannerPicker) {
            ImagePicker(image: $bannerImage, isPresented: $showBannerPicker)
        }
    }

    private func upload() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                if let image = profileImage {
                    _ = try await ProfileService.shared.updateProfileImage(image)
                }
                if let image = bannerImage {
                    _ = try await ProfileService.shared.updateBackgroundImage(image)
                }
                await MainActor.run {
                    isLoading = false
                    onNext()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct RegisterProfileImageView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterProfileImageView(onNext: {})
    }
}
