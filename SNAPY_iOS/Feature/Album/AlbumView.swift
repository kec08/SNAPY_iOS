//
//  AlbumView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct AlbumView: View {
    @StateObject private var viewModel = AlbumViewModel()
    @ObservedObject private var photoStore = PhotoStore.shared

    @State private var dragOffset: CGFloat = 0

    // MainTabView에서 카메라 열기 위한 콜백
    var onOpenCamera: () -> Void

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                AlbumHeader(
                    dateString: viewModel.dateString,
                    goToPreviousDay: { viewModel.goToPreviousDay() },
                    goToNextDay: { viewModel.goToNextDay() }
                )
                .padding(.bottom, 20)

                AlbumStrick(streakCount: viewModel.streakCount)
                    .padding(.bottom, -14)

                // 5칸 슬롯
                TabView(selection: $viewModel.currentPage) {
                    ForEach(AlbumSlot.allCases, id: \.rawValue) { slot in
                        AlbumTimeSlotCard(
                            slot: slot,
                            photo: viewModel.photo(for: slot),
                            emptyState: viewModel.emptySlotState(for: slot),
                            onTapSnap: onOpenCamera
                        )
                        .tag(slot.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(nil, value: viewModel.currentPage)
                .offset(x: dragOffset)
                .clipped()
            }
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            viewModel.currentPage = TimeSlot.current.rawValue
        }
        .onChange(of: viewModel.slideDirection) { _, direction in
            guard direction != .none else { return }
            performSlideAnimation(direction: direction)
        }
    }

    private func performSlideAnimation(direction: AlbumViewModel.SlideDirection) {
        let screenWidth: CGFloat = 400

        withAnimation(.easeIn(duration: 0.15)) {
            dragOffset = direction == .left ? -screenWidth : screenWidth
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            dragOffset = direction == .left ? screenWidth : -screenWidth
            withAnimation(.easeOut(duration: 0.2)) {
                dragOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.slideDirection = .none
            }
        }
    }
}

struct AlbumView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView(onOpenCamera: {})
    }
}
