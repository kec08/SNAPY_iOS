//
//  PhotoStore.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/21/26.
//

import Foundation
import SwiftUI
import Combine

// 앨범 5칸: 아침, 점심, 저녁, 추가1, 추가2
enum AlbumSlot: Int, CaseIterable {
    case morning = 0
    case afternoon = 1
    case evening = 2
    case extra1 = 3
    case extra2 = 4

    var name: String {
        switch self {
        case .morning:   return "아침"
        case .afternoon: return "점심"
        case .evening:   return "저녁"
        case .extra1:    return "추가"
        case .extra2:    return "추가"
        }
    }

    var timeRange: String {
        switch self {
        case .morning:   return "06:00 ~ 12:00"
        case .afternoon: return "12:00 ~ 18:00"
        case .evening:   return "18:00 ~ 06:00"
        case .extra1:    return "추가 촬영 1"
        case .extra2:    return "추가 촬영 2"
        }
    }
}

// 시간대 구분 (촬영 시점 분류용)
enum TimeSlot: Int, CaseIterable {
    case morning = 0
    case afternoon = 1
    case evening = 2

    static var current: TimeSlot {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return .morning
        case 12..<18: return .afternoon
        default:      return .evening
        }
    }

    static func from(date: Date) -> TimeSlot {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<12:  return .morning
        case 12..<18: return .afternoon
        default:      return .evening
        }
    }

    // TimeSlot → 대응하는 기본 AlbumSlot
    var albumSlot: AlbumSlot {
        switch self {
        case .morning:   return .morning
        case .afternoon: return .afternoon
        case .evening:   return .evening
        }
    }
}

struct SavedPhoto: Identifiable {
    let id = UUID()
    let frontImage: UIImage?
    let backImage: UIImage?
    let timeSlot: TimeSlot
    let albumSlot: AlbumSlot  // 실제 배치된 슬롯
    let capturedAt: Date
}

struct DailyAlbum: Identifiable {
    let id = UUID()
    let date: Date
    var photos: [SavedPhoto]

    // 특정 앨범 슬롯의 사진
    func photo(for slot: AlbumSlot) -> SavedPhoto? {
        photos.first { $0.albumSlot == slot }
    }

    var photoCount: Int { photos.count }
    var isFull: Bool { photos.count >= 5 }

    // 다음 빈 슬롯 찾기: 시간대 칸 우선 → 추가 칸 순서
    func nextAvailableSlot(for timeSlot: TimeSlot) -> AlbumSlot? {
        // 1) 해당 시간대의 기본 슬롯이 비어있으면 거기
        let primarySlot = timeSlot.albumSlot
        if photo(for: primarySlot) == nil {
            return primarySlot
        }

        // 2) 추가1 → 추가2 순서로 빈 칸 찾기
        if photo(for: .extra1) == nil { return .extra1 }
        if photo(for: .extra2) == nil { return .extra2 }

        // 3) 다 찼으면 nil
        return nil
    }
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

    /// 오늘 더 찍을 수 있는지 (5장 제한)
    var canTakePhoto: Bool {
        guard let album = todayAlbum else { return true }
        return !album.isFull
    }

    /// 카메라에서 저장하기 눌렀을 때 호출
    func savePhoto(front: UIImage?, back: UIImage?, capturedAt: Date) {
        let timeSlot = TimeSlot.from(date: capturedAt)

        // 기존 앨범이 있으면 슬롯 배치, 없으면 새 앨범 생성
        if let index = dailyAlbums.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: capturedAt) }) {
            guard let slot = dailyAlbums[index].nextAvailableSlot(for: timeSlot) else {
                print("앨범이 가득 찼습니다 (5/5)")
                return
            }

            let saved = SavedPhoto(
                frontImage: front,
                backImage: back,
                timeSlot: timeSlot,
                albumSlot: slot,
                capturedAt: capturedAt
            )
            dailyAlbums[index].photos.append(saved)
        } else {
            // 새 앨범: 해당 시간대의 기본 슬롯에 배치
            let saved = SavedPhoto(
                frontImage: front,
                backImage: back,
                timeSlot: timeSlot,
                albumSlot: timeSlot.albumSlot,
                capturedAt: capturedAt
            )
            let newAlbum = DailyAlbum(date: capturedAt, photos: [saved])
            dailyAlbums.insert(newAlbum, at: 0)
        }
    }
}
