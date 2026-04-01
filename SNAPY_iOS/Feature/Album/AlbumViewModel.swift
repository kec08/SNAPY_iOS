//
//  AlbumViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import Foundation
import SwiftUI
import Combine

// 빈 슬롯의 상태
enum EmptySlotState {
    case canTake
    case missed
}

@MainActor
final class AlbumViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentPage: Int = TimeSlot.current.rawValue
    @Published var slideDirection: SlideDirection = .none

    enum SlideDirection {
        case none, left, right
    }

    var dateString: String {
        selectedDate.albumDateString
    }

    func photo(for slot: AlbumSlot) -> SavedPhoto? {
        guard let album = PhotoStore.shared.album(for: selectedDate) else { return nil }
        return album.photo(for: slot)
    }

    var streakCount: Int {
        guard let album = PhotoStore.shared.album(for: selectedDate) else { return 0 }
        return min(album.photoCount, 5)
    }

    /// 찍을 수 있냐 없냐 여부
    func emptySlotState(for slot: AlbumSlot) -> EmptySlotState {
        let isToday = Calendar.current.isDateInToday(selectedDate)

        // 과거 날짜 missed
        if !isToday {
            return .missed
        }

        let currentSlot = TimeSlot.current

        switch slot {
        case .morning:
            return currentSlot == .morning ? .canTake : .missed
        case .afternoon:
            return currentSlot == .evening ? .missed : .canTake
        case .evening:
            return .canTake
        case .extra1, .extra2:
            let album = PhotoStore.shared.album(for: selectedDate)
            let count = album?.photoCount ?? 0
            return count < 5 ? .canTake : .missed
        }
    }

    func goToPreviousDay() {
        slideDirection = .right
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    func goToNextDay() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        if tomorrow <= Date() {
            slideDirection = .left
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDate = tomorrow
            }
        }
    }
}
