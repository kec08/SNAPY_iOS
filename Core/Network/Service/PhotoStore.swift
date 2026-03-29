//
//  PhotoStore.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/21/26.
//

import Foundation
import SwiftUI
import Combine

// 시간대 구분: 아침/점심/저녁
// Date+Extensions의 timeSlotName과 동일한 기준 사용
enum TimeSlot: Int, CaseIterable {
    case morning = 0   // 06:00 ~ 12:00
    case afternoon = 1 // 12:00 ~ 18:00
    case evening = 2   // 18:00 ~ 06:00

    var name: String {
        switch self {
        case .morning:   return "아침"
        case .afternoon: return "점심"
        case .evening:   return "저녁"
        }
    }

    var timeRange: String {
        switch self {
        case .morning:   return "06:00 ~ 12:00"
        case .afternoon: return "12:00 ~ 18:00"
        case .evening:   return "18:00 ~ 06:00"
        }
    }

    // 현재 시간 기준 TimeSlot
    static var current: TimeSlot {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return .morning
        case 12..<18: return .afternoon
        default:      return .evening
        }
    }

    // Date에서 TimeSlot 추출
    static func from(date: Date) -> TimeSlot {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<12:  return .morning
        case 12..<18: return .afternoon
        default:      return .evening
        }
    }
}

struct SavedPhoto: Identifiable {
    let id = UUID()
    let frontImage: UIImage?
    let backImage: UIImage?
    let timeSlot: TimeSlot
    let capturedAt: Date
}

struct DailyAlbum: Identifiable {
    let id = UUID()
    let date: Date
    var photos: [SavedPhoto]

    // 특정 시간대 사진 가져오기
    func photos(for slot: TimeSlot) -> [SavedPhoto] {
        photos.filter { $0.timeSlot == slot }
    }

    // 오늘 찍은 사진 수 (스트릭용)
    var photoCount: Int { photos.count }
}

@MainActor
final class PhotoStore: ObservableObject {
    static let shared = PhotoStore()

    @Published var dailyAlbums: [DailyAlbum] = []

    private init() {}

    var todayAlbum: DailyAlbum? {
        dailyAlbums.first { Calendar.current.isDateInToday($0.date) }
    }

    func album(for date: Date) -> DailyAlbum? {
        dailyAlbums.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    /// 카메라에서 저장하기 눌렀을 때 호출
    func savePhoto(front: UIImage?, back: UIImage?, capturedAt: Date) {
        let timeSlot = TimeSlot.from(date: capturedAt)
        let saved = SavedPhoto(
            frontImage: front,
            backImage: back,
            timeSlot: timeSlot,
            capturedAt: capturedAt
        )

        // 오늘 앨범이 있으면 추가, 없으면 새로 생성
        if let index = dailyAlbums.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: capturedAt) }) {
            dailyAlbums[index].photos.append(saved)
        } else {
            let newAlbum = DailyAlbum(date: capturedAt, photos: [saved])
            dailyAlbums.insert(newAlbum, at: 0)
        }
    }
}
