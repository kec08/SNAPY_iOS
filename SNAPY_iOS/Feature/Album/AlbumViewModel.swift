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

    // 현재 시간대 슬롯으로 초기 페이지
    @Published var currentPage: Int = TimeSlot.current.rawValue

    @Published var slideDirection: SlideDirection = .none

    enum SlideDirection {
        case none, left, right
    }

    var dateString: String {
        selectedDate.albumDateString
    }

    // 특정 앨범 슬롯의 사진
    func photo(for slot: AlbumSlot) -> SavedPhoto? {
        guard let album = PhotoStore.shared.album(for: selectedDate) else { return nil }
        return album.photo(for: slot)
    }

    // 스트릭: 오늘 찍은 사진 수 (최대 5)
    var streakCount: Int {
        guard let album = PhotoStore.shared.album(for: selectedDate) else { return 0 }
        return min(album.photoCount, 5)
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
