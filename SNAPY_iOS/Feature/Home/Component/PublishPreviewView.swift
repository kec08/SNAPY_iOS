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
    @ObservedObject var homeViewModel: HomeViewModel

    @State private var isPublishing = false
    @State private var errorMessage: String?
    @State private var showConfirmDialog = false

    private var todayPhotos: [PhotoData] {
        photoStore.todayAlbum?.photos ?? []
    }

    private var isAlreadyPublished: Bool {
        guard let albumId = todayAlbumId else { return false }
        return photoStore.hasPublished(albumId: albumId)
    }

    private var todayAlbumId: Int? {
        photoStore.todayAlbum?.albumId
    }

    /// 현재 시각 기준 아직 지나지 않은 식사 슬롯 이름들.
    /// 게시하면 이 슬롯들의 사진은 더 이상 추가할 수 없으므로 사용자에게 안내한다.
    private var upcomingMealSlots: [String] {
        let hour = Calendar.current.component(.hour, from: Date())
        var result: [String] = []
        if hour < 6  { result.append("아침") }
        if hour < 12 { result.append("점심") }
        if hour < 17 { result.append("저녁") }
        return result
    }

    /// 확인 다이얼로그에 띄울 안내 문구.
    private var upcomingSlotWarningMessage: String {
        let names = upcomingMealSlots
        guard !names.isEmpty else { return "" }
        let joined = names.joined(separator: ", ")
        return "지금 게시하면 \(joined) 게시물은 올라가지 않아요.\n그래도 게시할까요?"
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
        .alert("아직 남은 시간대가 있어요",
               isPresented: $showConfirmDialog) {
            Button("취소", role: .cancel) { }
            Button("게시할게요") { performPublish() }
        } message: {
            Text(upcomingSlotWarningMessage)
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

            // 이미 게시한 앨범이면 안내문구, 그 외엔 에러 메시지(있다면)
            if isAlreadyPublished {
                Text("오늘은 이미 게시했어요!\n내일 다시 만나요 🐧")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.customGray300)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.customRed)
                    .padding(.bottom, 6)
            }

            // 게시하기 버튼
            Button {
                publishAlbum()
            } label: {
                HStack(spacing: 8) {
                    if isPublishing {
                        ProgressView()
                            .tint(.textWhite)
                    } else {
                        Image(systemName: "paperplane")
                            .font(.system(size: 20, weight: .medium))
                        Text(isAlreadyPublished ? "오늘 게시 완료" : "게시하기")
                            .font(.system(size: 22, weight: .semibold))
                    }
                }
                .foregroundColor(isAlreadyPublished ? .customGray300 : .textWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .disabled(isPublishing || todayAlbumId == nil || isAlreadyPublished)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }

    // MARK: - 게시 동작

    /// 버튼 탭 핸들러: 1) 이미 게시한 앨범인지 체크 → 2) 미게시 슬롯 확인 → 3) 게시
    private func publishAlbum() {
        guard let albumId = todayAlbumId, !isPublishing else { return }

        // 이미 게시한 앨범이면 차단
        if photoStore.hasPublished(albumId: albumId) {
            errorMessage = "오늘은 이미 게시했어요!\n내일 다시 만나요 🐧"
            return
        }

        if upcomingMealSlots.isEmpty {
            performPublish()
        } else {
            showConfirmDialog = true
        }
    }

    /// 실제 publish API 호출.
    private func performPublish() {
        guard let albumId = todayAlbumId, !isPublishing else { return }
        isPublishing = true
        errorMessage = nil

        let photosToPost = todayPhotos

        Task {
            do {
                _ = try await AlbumService.shared.publish(albumId: albumId)
                photoStore.markPublished(albumId: albumId)
                homeViewModel.prependPublishedPost(photos: photosToPost)
                isPublishing = false
                dismiss()
            } catch let error as AlbumError {
                // 서버에서 "이미 게시됨" 409 → 로컬에도 마킹
                if let desc = error.errorDescription, desc.contains("이미") {
                    photoStore.markPublished(albumId: albumId)
                }
                errorMessage = error.errorDescription
                isPublishing = false
            } catch {
                errorMessage = error.localizedDescription
                isPublishing = false
            }
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
        PublishPreviewView(homeViewModel: HomeViewModel())
    }
}
