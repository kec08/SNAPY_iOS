//
//  PublishPreviewSheet.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI

struct PublishPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var photoStore = PhotoStore.shared

    private var todayPhotos: [PhotoData] {
        photoStore.todayAlbum?.photos ?? []
    }

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // 상단 네비게이션
                header

                if todayPhotos.isEmpty {
                    emptyStateView
                } else {
                    contentView
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await photoStore.loadToday()
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("게시하기")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textWhite)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 52)
    }

    // MARK: - 사진 있을 때

    private var contentView: some View {
        VStack(spacing: 0) {
            Text("오늘의 히스토리")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.textWhite)
                .padding(.top, 32)
                .padding(.bottom, 44)

            GeometryReader { geo in
                let cardWidth = geo.size.width * 0.72
                let cardHeight = cardWidth * 1.45
                let sidePadding = (geo.size.width - cardWidth) / 2

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(todayPhotos, id: \.id) { photo in
                            PublishPhotoCard(photo: photo)
                                .frame(width: cardWidth, height: cardHeight)
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.94)
                                        .opacity(phase.isIdentity ? 1.0 : 0.55)
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, sidePadding)
                }
                .scrollTargetBehavior(.viewAligned)
                .frame(width: geo.size.width, height: cardHeight)
            }

            Spacer()

            // 게시하기 버튼 (기능은 추후)
            Button {
                // TODO: 게시 로직 연결
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 20, weight: .medium))
                    Text("게시하기")
                        .font(.system(size: 22, weight: .semibold))
                }
                .foregroundColor(.textWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }

    // MARK: - 사진 없을 때

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("Crying_img")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            Text("오늘 찍은 사진이 없습니다")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.customGray300)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 사진 카드 (앞/뒤 듀얼)

private struct PublishPhotoCard: View {
    let photo: PhotoData

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // 후면 (메인)
                AsyncImage(url: URL(string: photo.backImageUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(ProgressView().tint(.white))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    case .failure:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.customGray300)
                            )
                    @unknown default:
                        Color.clear
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // 전면 (PIP)
                AsyncImage(url: URL(string: photo.frontImageUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        Color.white.opacity(0.1).overlay(ProgressView().tint(.white))
                    case .failure:
                        Color.white.opacity(0.1).overlay(
                            Image(systemName: "photo").foregroundColor(.customGray300)
                        )
                    @unknown default:
                        Color.clear
                    }
                }
                .frame(width: geo.size.width * 0.32, height: geo.size.width * 0.42)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.4), lineWidth: 1)
                )
                .padding(12)
            }
        }
    }
}

#Preview("PublishPreviewView") {
    NavigationStack {
        PublishPreviewView()
    }
}
