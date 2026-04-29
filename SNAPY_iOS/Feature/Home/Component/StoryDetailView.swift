//
//  StoryDetailView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/18/26.
//

import SwiftUI
import Kingfisher

/// 스토리 좋아요 상태 캐시 (앱 실행 동안 유지)
enum StoryLikeCache {
    private static var store: [String: Bool] = [:]

    static func key(storyId: Int, type: String) -> String { "\(storyId)-\(type)" }
    static func get(storyId: Int, type: String) -> Bool { store[key(storyId: storyId, type: type)] ?? false }
    static func set(storyId: Int, type: String, liked: Bool) { store[key(storyId: storyId, type: type)] = liked }
}

struct StoryDetailView: View {
    let stories: [StoryItem]
    let initialIndex: Int
    var onStorySeen: ((Int) -> Void)?   // storyId 전달

    @Environment(\.dismiss) private var dismiss

    @State private var currentUserIndex: Int = 0
    @State private var currentImageIndex: Int = 0
    @State private var progress: CGFloat = 0.0
    @State private var isPaused: Bool = false
    @State private var hideUI: Bool = false
    @State private var isLiked: Bool = false
    @State private var showHeartPop: Bool = false
    @State private var timer: Timer?

    // 좌우 드래그
    @State private var dragX: CGFloat = 0.0
    @State private var isDraggingH: Bool = false
    // 아래 드래그 dismiss
    @State private var dragY: CGFloat = 0.0
    @State private var isDraggingV: Bool = false

    private let autoAdvanceInterval: TimeInterval = 10.0
    private let timerTickInterval: TimeInterval = 0.05
    private let pageGap: CGFloat = 6

    var currentStory: StoryItem {
        stories[currentUserIndex]
    }

    var currentPhotos: [StoryPhotoSet] {
        currentStory.photos
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                // 페이지 슬라이드
                HStack(spacing: pageGap) {
                    ForEach(0..<stories.count, id: \.self) { userIndex in
                        storyPage(
                            for: userIndex,
                            imageIndex: userIndex == currentUserIndex ? currentImageIndex : 0,
                            size: geo.size
                        )
                        .cornerRadius(isDraggingH ? 16 : 0)
                    }
                }
                .offset(x: -CGFloat(currentUserIndex) * (geo.size.width + pageGap) + dragX)


            }
            .offset(y: dragY)
            .opacity(1.0 - Double(max(dragY, 0)) / 600.0)
            .ignoresSafeArea()
            .simultaneousGesture(longPressGesture)
            .simultaneousGesture(combinedDragGesture(screenWidth: geo.size.width))
        }
        .background(Color.black.opacity(1.0 - Double(max(dragY, 0)) / 400.0))
        .statusBarHidden()
        .onAppear {
            currentUserIndex = initialIndex
            startTimer()
            onStorySeen?(stories[initialIndex].storyId)
            loadLikeStatus()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - 개별 스토리 페이지

    @ViewBuilder
    private func storyPage(for userIndex: Int, imageIndex: Int, size: CGSize) -> some View {
        let story = stories[userIndex]
        let photos = story.photos
        let safeImageIndex = min(imageIndex, max(photos.count - 1, 0))

        ZStack {
            // 1) 배경 이미지
            storyPhotoContent(photo: photos.isEmpty ? nil : photos[safeImageIndex], size: size)

            // 2) 탭 네비게이션 (이전/다음) — 하단 버튼 영역 제외
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { goToPrevious() }
                        .frame(width: size.width * 0.25)

                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { goToNext() }
                }

                // 하단 버튼 영역만큼 비움 (탭 전파 차단)
                Color.clear
                    .frame(height: 80)
                    .allowsHitTesting(false)
            }

            // 3) UI 오버레이 (프로그레스바, 프로필, 버튼)
            if !hideUI {
                VStack(spacing: 0) {
                    // 상단
                    VStack(spacing: 8) {
                        // 프로그레스 바
                        HStack(spacing: 4) {
                            ForEach(0..<photos.count, id: \.self) { idx in
                                GeometryReader { barGeo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.white.opacity(0.3))
                                            .frame(height: 2.5)

                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.white)
                                            .frame(
                                                width: userIndex == currentUserIndex
                                                    ? barWidth(for: idx, totalWidth: barGeo.size.width)
                                                    : 0,
                                                height: 2.5
                                            )
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                        .padding(.horizontal, 12)
                        .allowsHitTesting(false)

                        // 프로필 정보
                        HStack(spacing: 12) {
                            profileImageView(name: story.profileImage)
                                .frame(width: 40, height: 40)
                                .clipped()
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(story.displayName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.textWhite)

                                Text(story.username)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.customGray200)
                            }

                            if !story.relativeTimeText.isEmpty {
                                Text(story.relativeTimeText)
                                    .font(.system(size: 13))
                                    .foregroundColor(.customGray200)
                                    .padding(.leading, 4)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .allowsHitTesting(false)
                    }
                    .padding(.top, 16)

                    Spacer()

                    // 하단 그라데이션
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                    .allowsHitTesting(false)
                    .padding(.bottom, -100)

                    // 하단 버튼
                    if userIndex == currentUserIndex {
                        let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""
                        let isMyStory = story.username == myHandle

                        HStack(spacing: 20) {
                            Spacer()

                            if !isMyStory {
                                Button {
                                    triggerLike()
                                } label: {
                                    ZStack {
                                        // 탭 피드백: 위로 튀어오르는 하트
                                        if showHeartPop {
                                            Image("Heart_img")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 36, height: 36)
                                                .transition(.asymmetric(
                                                    insertion: .scale(scale: 0.2).combined(with: .opacity),
                                                    removal: .opacity.combined(with: .offset(y: -20))
                                                ))
                                                .offset(y: -50)
                                        }

                                        Image(systemName: isLiked ? "heart.fill" : "heart")
                                            .font(.system(size: 28))
                                            .foregroundColor(isLiked ? .red : .white)
                                    }
                                    .frame(width: 48, height: 48)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                // 공유
                            } label: {
                                Image(systemName: "paperplane")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .frame(width: 48, height: 48)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    // MARK: - 이미지 컨텐츠 (back 배경 + front PIP)

    @ViewBuilder
    private func storyPhotoContent(photo: StoryPhotoSet?, size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            // 배경: back 이미지
            if let backUrl = photo?.backImageUrl, let url = URL(string: backUrl) {
                KFImage(url)
                    .resizable()
                    .placeholder { Color.customGray500 }
                    .fade(duration: 0.2)
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
            } else {
                Color.customGray500
                    .frame(width: size.width, height: size.height)
            }

            // PIP: front 이미지
            if let frontUrl = photo?.frontImageUrl, let url = URL(string: frontUrl) {
                KFImage(url)
                    .resizable()
                    .placeholder { Color.customGray500 }
                    .fade(duration: 0.2)
                    .scaledToFill()
                    .frame(width: 130, height: 180)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.top, 80)
                    .padding(.leading, 14)
            }
        }
    }

    @ViewBuilder
    private func profileImageView(name: String) -> some View {
        if name.isImageURL, let url = URL(string: name) {
            KFImage(url)
                .resizable()
                .placeholder { Color.customGray500 }
                .fade(duration: 0.2)
                .scaledToFill()
        } else {
            Image(name)
                .resizable()
                .scaledToFill()
        }
    }

    // MARK: - 프로그레스 바

    private func barWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentImageIndex {
            return totalWidth
        } else if index == currentImageIndex {
            return totalWidth * progress
        } else {
            return 0
        }
    }

    // MARK: - 타이머

    private func startTimer() {
        stopTimer()
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: timerTickInterval, repeats: true) { _ in
            Task { @MainActor in
                guard !isPaused else { return }
                progress += timerTickInterval / autoAdvanceInterval
                if progress >= 0.7 {
                    goToNext()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - 네비게이션

    private func goToNext() {
        if currentImageIndex < currentPhotos.count - 1 {
            currentImageIndex += 1
            progress = 0
            loadLikeStatus()
        } else if currentUserIndex < stories.count - 1 {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentUserIndex += 1
            }
            currentImageIndex = 0
            progress = 0
            onStorySeen?(stories[currentUserIndex].storyId)
            startTimer()
            loadLikeStatus()
        } else {
            dismiss()
        }
    }

    private func goToPrevious() {
        if currentImageIndex > 0 {
            currentImageIndex -= 1
            progress = 0
            loadLikeStatus()
        } else if currentUserIndex > 0 {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentUserIndex -= 1
            }
            currentImageIndex = stories[currentUserIndex].photos.count - 1
            progress = 0
            startTimer()
            loadLikeStatus()
        }
    }

    // MARK: - 좋아요

    /// 햅틱 + 팝 애니메이션 + API 호출
    private func triggerLike() {
        let willLike = !isLiked  // 토글 후 좋아요 상태

        // 짧은 햅틱 진동
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // 좋아요일 때만 팝 애니메이션
        if willLike {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                showHeartPop = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showHeartPop = false
                }
            }
        }

        toggleLikeAPI()
    }

    private func toggleLikeAPI() {
        let story = currentStory
        let photos = story.photos
        guard currentImageIndex < photos.count else {
            print("[StoryDetail] guard 실패: currentImageIndex(\(currentImageIndex)) >= photos.count(\(photos.count))")
            return
        }
        let photo = photos[currentImageIndex]
        guard let type = photo.albumType else {
            print("[StoryDetail] guard 실패: albumType nil (type=\(photo.type))")
            return
        }

        // 즉시 UI 반영 (낙관적 업데이트)
        isLiked.toggle()

        Task {
            do {
                let result = try await StoryService.shared.toggleLike(
                    storyId: story.storyId,
                    type: type
                )
                await MainActor.run {
                    isLiked = result.liked
                    StoryLikeCache.set(storyId: story.storyId, type: type.rawValue, liked: result.liked)
                }
            } catch {
                print("[StoryDetail] 좋아요 실패: \(error)")
                await MainActor.run {
                    isLiked.toggle()
                }
            }
        }
    }

    /// 로컬 캐시에서 좋아요 상태 복원
    private func loadLikeStatus() {
        let story = currentStory
        let photos = story.photos
        guard currentImageIndex < photos.count,
              let type = photos[currentImageIndex].albumType else {
            isLiked = false
            return
        }
        isLiked = StoryLikeCache.get(storyId: story.storyId, type: type.rawValue)
    }

    // MARK: - 제스처

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .second(true, _):
                    isPaused = true
                    hideUI = true
                default:
                    break
                }
            }
            .onEnded { _ in
                isPaused = false
                hideUI = false
            }
    }

    private func combinedDragGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                let hDrag = abs(value.translation.width)
                let vDrag = abs(value.translation.height)

                // 방향 잠금
                if !isDraggingH && !isDraggingV {
                    if vDrag > hDrag && value.translation.height > 0 {
                        isDraggingV = true
                    } else if hDrag > vDrag {
                        isDraggingH = true
                    }
                }

                if isDraggingV {
                    dragY = max(value.translation.height, 0)
                    isPaused = true
                } else if isDraggingH {
                    dragX = value.translation.width
                    isPaused = true
                }
            }
            .onEnded { value in
                if isDraggingV {
                    if dragY > 120 {
                        withAnimation(.easeOut(duration: 0.3)) {
                            dragY = 1000
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragY = 0
                        }
                        isPaused = false
                    }
                } else if isDraggingH {
                    let threshold: CGFloat = screenWidth * 0.25

                    if value.translation.width < -threshold && currentUserIndex < stories.count - 1 {
                        withAnimation(.easeOut(duration: 0.35)) {
                            currentUserIndex += 1
                            dragX = 0
                        }
                        currentImageIndex = 0
                        progress = 0
                        isLiked = false
                        isPaused = false
                        startTimer()
                    } else if value.translation.width > threshold && currentUserIndex > 0 {
                        withAnimation(.easeOut(duration: 0.35)) {
                            currentUserIndex -= 1
                            dragX = 0
                        }
                        currentImageIndex = stories[currentUserIndex].photos.count - 1
                        progress = 0
                        isLiked = false
                        isPaused = false
                        startTimer()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragX = 0
                        }
                        isPaused = false
                    }
                }

                isDraggingH = false
                isDraggingV = false
            }
    }
}

// MARK: - Preview

#Preview("StoryDetail") {
    StoryDetailView(
        stories: [
            StoryItem(
                storyId: 1,
                profileImage: "Profile_img",
                bannerImage: "Mock_img1",
                displayName: "은찬",
                username: "silver_c_Id",
                photos: [
                    StoryPhotoSet(type: "MORNING", frontImageUrl: "Mock_img1", backImageUrl: "Mock_img1", createdAt: nil),
                    StoryPhotoSet(type: "LUNCH", frontImageUrl: "Mock_img2", backImageUrl: "Mock_img2", createdAt: nil),
                ],
                createdAt: nil,
                isSeen: false
            ),
        ],
        initialIndex: 0
    )
}
