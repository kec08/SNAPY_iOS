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
                    .padding(.bottom, 16)

                TabView(selection: $viewModel.currentPage) {
                    ForEach(TimeSlot.allCases, id: \.rawValue) { slot in
                        AlbumTimeSlotCard(
                            slot: slot,
                            photos: viewModel.photos(for: slot)
                        )
                        .tag(slot.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            viewModel.currentPage = TimeSlot.current.rawValue
        }
    }
}

struct AlbumView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView()
    }
}
