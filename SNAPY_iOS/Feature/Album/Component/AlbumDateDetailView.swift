//
//  AlbumDateDetailView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/10/26.
//

import SwiftUI

/// 캘린더에서 날짜 탭 시 push 되는 앨범 뷰.
/// 오늘이면 todayAlbum, 과거 날짜면 서버에서 albumId 로 상세 조회.
struct AlbumDateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var photoStore = PhotoStore.shared

    let date: Date
    @State private var currentPage: Int = 0

    private let calendar = Calendar.current

    var dateString: String {
        date.albumDateString
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
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
            if isToday {
                await photoStore.loadToday()
            } else if let albumId = photoStore.albumId(for: date) {
                await photoStore.loadAlbumById(albumId)
            }
        }
        .onDisappear {
            // 나갈 때 selectedDateAlbum 정리
            if !isToday {
                photoStore.selectedDateAlbum = nil
            }
        }
    }

    // MARK: - 데이터 헬퍼

    private func photo(for slot: AlbumSlot) -> PhotoData? {
        if isToday {
            return photoStore.todayPhoto(for: slot)
        } else {
            return photoStore.selectedDatePhoto(for: slot)
        }
    }

    private var streakCount: Int {
        if isToday {
            return min(photoStore.todayPhotoCount, 5)
        } else {
            return min(photoStore.selectedDatePhotoCount, 5)
        }
    }

    private func emptySlotState(for slot: AlbumSlot) -> EmptySlotState {
        // 과거 날짜는 더 이상 찍을 수 없으므로 사진 없으면 missed
        if !isToday { return .missed }

        let currentSlot = TimeSlot.current
        switch slot {
        case .morning:
            return currentSlot == .morning ? .canTake : .missed
        case .afternoon:
            return (currentSlot == .evening || currentSlot == .extra) ? .missed : .canTake
        case .evening:
            return .canTake
        case .extra1, .extra2:
            return photoStore.todayPhotoCount < 5 ? .canTake : .missed
        }
    }
}
