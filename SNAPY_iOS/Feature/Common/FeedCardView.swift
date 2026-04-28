//
//  FeedCardView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/29/26.
//

import SwiftUI
import Kingfisher

/// 홈 피드와 프로필 피드 상세에서 공통으로 사용하는 피드 카드
struct FeedCardView: View {
    let profileImageSource: ProfileImageSource
    let displayName: String
    let handle: String
    let date: String
    let photos: [FeedCardPhoto]

    // 스토리 테두리 (홈에서만 사용)
    var hasStory: Bool = false
    var isStorySeen: Bool = true

    // 좋아요/댓글 상태
    @Binding var isLiked: Bool
    @Binding var likeCount: Int
    var commentCount: Int = 0

    // 콜백
    var onLike: (() -> Void)? = nil
    var onProfileImageTap: (() -> Void)? = nil
    var onNameTap: (() -> Void)? = nil

    @State private var currentPage = 0
    @State private var showComments = false
    @State private var heartAnimations: [HeartAnimation] = []
    @State private var heartTapCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: 프로필 헤더
            HStack(spacing: 14) {
                Button {
                    onProfileImageTap?()
                } label: {
                    profileImage
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .padding(3)
                        .overlay(
                            Group {
                                if hasStory {
                                    Circle()
                                        .stroke(
                                            isStorySeen
                                                ? AnyShapeStyle(Color.customGray500)
                                                : AnyShapeStyle(
                                                    LinearGradient(
                                                        colors: [Color(hex: "FFC83D"), Color(hex: "FF9F1C")],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                ),
                                            lineWidth: 2
                                        )
                                }
                            }
                        )
                }

                Button {
                    onNameTap?()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text(handle)
                            .font(.system(size: 12))
                            .foregroundColor(.customGray300)
                    }
                }

                Spacer()

                Text(date)
                    .font(.system(size: 13))
                    .foregroundColor(.customGray300)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // MARK: 사진 슬라이더
            ZStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                        draggablePhotoView(for: photo)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                ForEach(heartAnimations) { heart in
                    Image("Heart_img")
                        .resizable()
                        .scaledToFit()
                        .frame(width: heart.size, height: heart.size)
                        .rotationEffect(.degrees(heart.rotation))
                        .scaleEffect(heart.scale)
                        .opacity(heart.opacity)
                        .position(heart.position)
                }
            }
            .frame(height: 540)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { location in
                triggerHeartAnimation(at: location)
                if !isLiked {
                    isLiked = true
                    likeCount += 1
                    onLike?()
                }
            }

            // MARK: 페이지 인디케이터
            HStack(spacing: 5) {
                if photos.count > 1 {
                    ForEach(0..<photos.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.MainYellow : Color.customGray300)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 6)
            .padding(.vertical, 14)

            // MARK: 액션 버튼
            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    Button {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                        onLike?()
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 26))
                            .foregroundColor(isLiked ? .red : .white)
                    }
                    Text("\(likeCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                HStack(spacing: 6) {
                    Button {
                        showComments = true
                    } label: {
                        Image("Chat_icon")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    Text("\(commentCount)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                Button {
                    // 공유
                } label: {
                    Image(systemName: "paperplane")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 20)

            ImageCommentSection()
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
        .sheet(isPresented: $showComments) {
            CommentSheetView(postId: UUID())
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - 프로필 이미지

    @ViewBuilder
    private var profileImage: some View {
        switch profileImageSource {
        case .url(let urlString):
            if let url = URL(string: urlString) {
                KFImage(url)
                    .resizable()
                    .downsampling(size: CGSize(width: 72, height: 72))
                    .loadDiskFileSynchronously()
                    .cacheOriginalImage()
                    .placeholder { Color.customGray500 }
                    .fade(duration: 0.15)
                    .scaledToFill()
            } else {
                defaultProfileImage
            }
        case .uiImage(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFill()
        case .none:
            defaultProfileImage
        }
    }

    private var defaultProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(.customGray300)
    }

    // MARK: - 사진 (back 배경 + front 드래그 PIP)

    @ViewBuilder
    private func draggablePhotoView(for photo: FeedCardPhoto) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                backImageView(photo.backImageUrl, asset: photo.assetName)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                if let frontUrl = photo.frontImageUrl, let url = URL(string: frontUrl) {
                    DraggablePIP(
                        containerSize: geo.size,
                        pipWidth: 120,
                        pipHeight: 160,
                        padding: 12
                    ) {
                        KFImage(url)
                            .resizable()
                            .placeholder { Color(white: 0.2) }
                            .fade(duration: 0.2)
                            .scaledToFill()
                    }
                }
            }
        }
    }

    // MARK: - 공통 back 이미지

    @ViewBuilder
    private func backImageView(_ urlString: String?, asset: String?) -> some View {
        if let backUrl = urlString, let url = URL(string: backUrl) {
            KFImage(url)
                .resizable()
                .downsampling(size: CGSize(width: UIScreen.main.bounds.width, height: 540))
                .placeholder { Color.customGray500 }
                .fade(duration: 0.15)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else if let asset, !asset.isEmpty {
            Image(asset)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            Color.customGray500
        }
    }

    // MARK: - 더블탭 하트

    private func triggerHeartAnimation(at location: CGPoint) {
        heartTapCount += 1
        let size: CGFloat = 60 + CGFloat(heartTapCount - 1) * 2
        let heart = HeartAnimation(position: location, size: min(size, 120))
        heartAnimations.append(heart)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            if let idx = heartAnimations.firstIndex(where: { $0.id == heart.id }) {
                heartAnimations[idx].scale = 1.2
                heartAnimations[idx].opacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                if let idx = heartAnimations.firstIndex(where: { $0.id == heart.id }) {
                    heartAnimations[idx].scale = 1.6
                    heartAnimations[idx].opacity = 0
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            heartAnimations.removeAll { $0.id == heart.id }
        }
    }
}

// MARK: - 공용 데이터 모델

enum ProfileImageSource {
    case url(String)
    case uiImage(UIImage)
    case asset(String)
    case none
}

struct FeedCardPhoto: Identifiable {
    let id = UUID()
    let frontImageUrl: String?
    let backImageUrl: String?
    let assetName: String?
}

// MARK: - 하트 애니메이션 모델

struct HeartAnimation: Identifiable {
    let id = UUID()
    let position: CGPoint
    let rotation: Double = Double.random(in: -30...30)
    var size: CGFloat = 60
    var scale: CGFloat = 0.0
    var opacity: Double = 0.0
}

// MARK: - 이미지 댓글 섹션

struct ImageCommentSection: View {
    @State private var showImagePicker = false

    private let reactions = ["Mock_img2", "Mock_img3", "Mock_img4", "Mock_img5", "Mock_img1", "Mock_img2", "Mock_img3", "Mock_img4"]

    var body: some View {
        HStack(spacing: 12) {
            Button {
                showImagePicker = true
            } label: {
                Circle()
                    .stroke(Color.customGray300, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.customGray300)
                    )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(reactions.indices, id: \.self) { index in
                        Image(reactions[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}
