//
//  AlbumViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AlbumViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentPage: Int = TimeSlot.current.rawValue

    // 날짜 전환 애니메이션 방향
    @Published var slideDirection: SlideDirection = .none

    enum SlideDirection {
        case none, left, right
    }

    var dateString: String {
        selectedDate.albumDateString
    }

    func photos(for slot: TimeSlot) -> [SavedPhoto] {
        guard let album = PhotoStore.shared.album(for: selectedDate) else { return [] }
        return album.photos(for: slot)
    }

    var streakCount: Int {
        guard let album = PhotoStore.shared.album(for: selectedDate) else { return 0 }
        return min(album.photoCount, 5)
    }

    func goToPreviousDay() {
        slideDirection = .right  // 이전 날짜 → 오른쪽에서 들어옴
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        }
    }

    func goToNextDay() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        if tomorrow <= Date() {
            slideDirection = .left  // 다음 날짜 → 왼쪽에서 들어옴
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedDate = tomorrow
            }
        }
    }
}
