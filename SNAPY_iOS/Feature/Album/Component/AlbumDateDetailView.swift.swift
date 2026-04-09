//
//  AlbumDateDetailView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/10/26.
//

import SwiftUI

/// 캘린더에서 날짜 탭 시 push 되는 앨범 뷰.
/// 헤더에 날짜 이동(< >) 대신 뒤로가기 버튼 + 날짜 타이틀만 표시.
struct AlbumDateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var photoStore = PhotoStore.shared

    let date: Date
    @State private var currentPage: Int = 0

    private let calendar = Calendar.current

    var dateString: String {
        date.albumDateString
    }

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                AlbumStrick(streakCount: streakCount)
                    .padding(.bottom, -14)
                    .padding(.top, 12)

                // 5칸 슬롯
                TabView(selection: $currentPage) {
                    ForEach(AlbumSlot.allCases, id: \.rawValue) { slot in
                        AlbumTimeSlotCard(
                            slot: slot,
                            photo: photo(for: slot),
                            emptyState: emptySlotState(for: slot),
                            onTapSnap: { }
                        )
                        .tag(slot.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(nil, value: currentPage)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textWhite)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(dateString)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textWhite)
            }
        }
        .toolbarBackground(Color.backgroundBlack, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            // 해당 날짜가 오늘이면 today 로드, 아니면 현재는 데이터 없음
            if calendar.isDateInToday(date) {
                await photoStore.loadToday()
            }
        }
    }

    // MARK: - 데이터 헬퍼

    private func photo(for slot: AlbumSlot) -> PhotoData? {
        guard calendar.isDateInToday(date) else { return nil }
        return photoStore.todayPhoto(for: slot)
    }

    private var streakCount: Int {
        guard calendar.isDateInToday(date) else { return 0 }
        return min(photoStore.todayPhotoCount, 5)
    }

    private func emptySlotState(for slot: AlbumSlot) -> EmptySlotState {
        let isToday = calendar.isDateInToday(date)
        if !isToday { return .missed }

        let currentSlot = TimeSlot.current
        switch slot {
        case .morning:
            return currentSlot == .morning ? .canTake : .missed
        case .afternoon:
            return currentSlot == .evening ? .missed : .canTake
        case .evening:
            return .canTake
        case .extra1, .extra2:
            return photoStore.todayPhotoCount < 5 ? .canTake : .missed
        }
    }
}
