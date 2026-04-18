//
//  StoryDetailView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/18/26.
//

import SwiftUI

struct StoryDetailView: View {
    let stories: [StoryItem]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss

    @State private var currentUserIndex: Int = 0
    @State private var currentImageIndex: Int = 0
    @State private var progress: CGFloat = 0.0
    @State private var isPaused: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var zoomAnchor: UnitPoint = .center
    @State private var hideUI: Bool = false
    @State private var isLiked: Bool = false
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

    var currentImages: [String] {
        currentStory.images
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
                .scaleEffect(max(scale, 0.5), anchor: zoomAnchor)
                .gesture(pinchGesture(in: geo.size))

                // 좌우 탭 영역 (인스타: 왼쪽 25% 이전, 오른쪽 75% 다음)
                HStack(spacing: 0) {
                    Color.white.opacity(0.001)
                        .onTapGesture { goToPrevious() }
                        .frame(width: geo.size.width * 0.25)

                    Color.white.opacity(0.001)
                        .onTapGesture { goToNext() }
                }
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
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - 개별 스토리 페이지

    @ViewBuilder
    private func storyPage(for userIndex: Int, imageIndex: Int, size: CGSize) -> some View {
        let story = stories[userIndex]
        let images = story.images
        let safeImageIndex = min(imageIndex, images.count - 1)

        ZStack {
            storyImageContent(imageName: images[safeImageIndex], size: size)

            if !hideUI {
                VStack(spacing: 0) {
                    // 상단
                    VStack(spacing: 8) {
                        // 프로그레스 바
                        HStack(spacing: 4) {
                            ForEach(0..<images.count, id: \.self) { idx in
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
                                .frame(height: 2.5)
                            }
                        }
                        .padding(.horizontal, 12)

                        // 프로필 정보
                        HStack(spacing: 10) {
                            profileImageView(name: story.profileImage)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(story.displayName)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.textWhite)

                                Text(story.username)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.textWhite)
                            }

                            Text("6시간")
                                .font(.system(size: 12))
                                .foregroundColor(.customGray100)

                            Spacer()
                        }
                        .padding(.horizontal, 14)
                    }
                    .padding(.top, 16)

                    Spacer()

                    // 하단 버튼
                    if userIndex == currentUserIndex {
                        HStack(spacing: 20) {
                            Spacer()

                            Button {
                                isLiked.toggle()
                            } label: {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 28))
                                    .foregroundColor(isLiked ? .red : .white)
                            }

                            Button {
                                // 공유
                            } label: {
                                Image(systemName: "paperplane")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 50)
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    // MARK: - 이미지 컨텐츠

    @ViewBuilder
    private func storyImageContent(imageName: String, size: CGSize) -> some View {
        if imageName.isImageURL, let url = URL(string: imageName) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    Color.customGray500
                @unknown default:
                    Color.customGray500
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        }
    }

    @ViewBuilder
    private func profileImageView(name: String) -> some View {
        if name.isImageURL, let url = URL(string: name) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Color.customGray500
                }
            }
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
        if currentImageIndex < currentImages.count - 1 {
            currentImageIndex += 1
            progress = 0
        } else if currentUserIndex < stories.count - 1 {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentUserIndex += 1
            }
            currentImageIndex = 0
            progress = 0
            isLiked = false
            startTimer()
        } else {
            dismiss()
        }
    }

    private func goToPrevious() {
        if currentImageIndex > 0 {
            currentImageIndex -= 1
            progress = 0
        } else if currentUserIndex > 0 {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentUserIndex -= 1
            }
            currentImageIndex = stories[currentUserIndex].images.count - 1
            progress = 0
            isLiked = false
            startTimer()
        }
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
                if scale != 1.0 {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scale = 1.0
                    }
                }
            }
    }

    private func pinchGesture(in size: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                isPaused = true
                hideUI = true
                scale = value.magnification

                let loc = value.startLocation
                zoomAnchor = UnitPoint(
                    x: loc.x / size.width,
                    y: loc.y / size.height
                )
            }
            .onEnded { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    scale = 1.0
                }
                isPaused = false
                hideUI = false
            }
    }

    private func combinedDragGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                guard scale <= 1.05 else { return }

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
                guard scale <= 1.05 else { return }

                if isDraggingV {
                    if dragY > 120 {
                        withAnimation(.easeOut(duration: 0.3)) {
                            dragY = UIScreen.main.bounds.height
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
                        currentImageIndex = stories[currentUserIndex].images.count - 1
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
            StoryItem(profileImage: "Profile_img", bannerImage: "Mock_img1", displayName: "은찬", username: "silver_c_Id", images: ["Mock_img1", "Mock_img2", "Mock_img3"], isSeen: false),
            StoryItem(profileImage: "Mock_img1", bannerImage: "Mock_img2", displayName: "민수", username: "user_02", images: ["Mock_img2", "Mock_img4"], isSeen: false),
        ],
        initialIndex: 0
    )
}
