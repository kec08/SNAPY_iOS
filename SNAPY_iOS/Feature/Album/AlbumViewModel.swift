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

    // 현재 시간대 → 해당 슬롯 인덱스로 초기 페이지 설정
    @Published var currentPage: Int = TimeSlot.current.rawValue

    var dateString: String {
        selectedDate.albumDateString
    }

    // 해당 날짜의 앨범에서 특정 시간대 사진 가져오기
    func photos(for slot: TimeSlot) -> [SavedPhoto] {
        guard let album = PhotoStore.shared.album(for: selectedDate) else { return [] }
        return album.photos(for: slot)
    }

    // 스트릭: 오늘 찍은 사진 수 (최대 5)
    var streakCount: Int {
        guard let album = PhotoStore.shared.album(for: selectedDate) else { return 0 }
        return min(album.photoCount, 5)
    }

    func goToPreviousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    func goToNextDay() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        // 미래 날짜는 못 감
        if tomorrow <= Date() {
            selectedDate = tomorrow
        }
    }
}
