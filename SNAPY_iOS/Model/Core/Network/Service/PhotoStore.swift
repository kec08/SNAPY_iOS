//
//  PhotoStore.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/21/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 화면용 슬롯 enum (5칸: 아침/점심/저녁/추가1/추가2)

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
        case .morning:   return "06:00 ~ 11:00"
        case .afternoon: return "12:00 ~ 16:00"
        case .evening:   return "17:00 ~ 24:00"
        case .extra1:    return "추가 촬영 1"
        case .extra2:    return "추가 촬영 2"
        }
    }
}

// MARK: - 시간대 (촬영 시점 → 기본 슬롯 결정용)

enum TimeSlot: Int, CaseIterable {
    case morning = 0
    case afternoon = 1
    case evening = 2
    case extra = 3      // 0-6, 11-12, 16-17 시간대

    static var current: TimeSlot {
        let hour = Calendar.current.component(.hour, from: Date())
        return from(hour: hour)
    }

    static func from(date: Date) -> TimeSlot {
        let hour = Calendar.current.component(.hour, from: date)
        return from(hour: hour)
    }

    private static func from(hour: Int) -> TimeSlot {
        switch hour {
        case 6..<11:   return .morning
        case 12..<16:  return .afternoon
        case 17..<24:  return .evening
        default:        return .extra   // 0-6, 11-12, 16-17
        }
    }

    /// 메인 시간대의 앨범 슬롯. extra 시간대는 nil.
    var albumSlot: AlbumSlot? {
        switch self {
        case .morning:   return .morning
        case .afternoon: return .afternoon
        case .evening:   return .evening
        case .extra:     return nil
        }
    }
}

// MARK: - PhotoStore (서버 응답 캐시)

@MainActor
final class PhotoStore: ObservableObject {
    static let shared = PhotoStore()

    /// 오늘 데일리 앨범 (photos 포함)
    @Published var todayAlbum: DailyAlbumData?

    /// 월간 앨범 목록 (썸네일만)
    @Published var monthAlbums: [AlbumListItemData] = []

    /// 캘린더 전용 캐시 — key: "yyyy-MM-dd", value: AlbumListItemData
    /// 다른 코드가 덮어쓸 수 없는 독립 저장소
    @Published var calendarCache: [String: AlbumListItemData] = [:]

    /// 앨범 상세 캐시 (albumId → list)
    @Published var detailCache: [Int: [AlbumListItemData]] = [:]

    /// 캘린더에서 선택한 특정 날짜의 앨범 (photos 포함)
    @Published var selectedDateAlbum: DailyAlbumData?

    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {
    }

    // MARK: - 조회

    func loadToday() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await AlbumService.shared.fetchToday()
            todayAlbum = data
            let types = data.photos.map { $0.type }
            print("[PhotoStore] loadToday 성공 - albumId=\(data.albumId), photoCount=\(data.photoCount), types=\(types)")
        } catch {
            errorMessage = error.localizedDescription
            print("[PhotoStore] loadToday 실패: \(error)")
            // today 가 없으면 nil 처리
            todayAlbum = nil
        }
        isLoading = false
        // 게시 상태도 로드 (body 렌더 중 @Published 변경 방지)
        if !publishedLoaded { loadPublishedState() }
    }

    func loadMonth(_ month: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let list = try await AlbumService.shared.fetchAlbums(month: month)
            monthAlbums = list
        } catch {
            errorMessage = error.localizedDescription
            monthAlbums = []
        }
        isLoading = false
    }

    /// 한 달치를 기존 monthAlbums 에 추가 (덮어쓰지 않음, 날짜 이동 시 사용)
    func appendMonth(_ month: Int) async {
        do {
            let list = try await AlbumService.shared.fetchAlbums(month: month)
            // 이미 있는 albumId 는 중복 추가하지 않음
            let existingIds = Set(monthAlbums.map { $0.albumId })
            let newItems = list.filter { !existingIds.contains($0.albumId) }
            monthAlbums.append(contentsOf: newItems)
        } catch {
            // 실패해도 기존 데이터 유지
        }
    }

    /// 캘린더용: 전체 앨범을 한 번에 받아서 calendarCache 에 저장
    func loadCalendar() async {
        do {
            let list = try await AlbumService.shared.fetchCalendar()
            // 새 응답으로 캐시를 통째로 교체 (오래된 항목 제거)
            var newCache: [String: AlbumListItemData] = [:]
            for item in list {
                newCache[item.albumDate] = item
            }
            calendarCache = newCache
        } catch {
            // 실패 시 기존 캐시 유지
        }
    }

    /// calendarCache 에서 날짜로 썸네일 조회
    func calendarThumbnail(for dateString: String) -> String? {
        calendarCache[dateString]?.thumbnailUrl
    }

    /// calendarCache 에서 날짜로 albumId 조회
    func calendarAlbumId(for dateString: String) -> Int? {
        calendarCache[dateString]?.albumId
    }

    /// 여러 달을 한 번에 로드해서 monthAlbums 에 합침 (캘린더용)
    func loadMonths(_ months: [Int]) async {
        isLoading = true
        errorMessage = nil
        var allItems: [AlbumListItemData] = []
        for month in months {
            do {
                let list = try await AlbumService.shared.fetchAlbums(month: month)
                allItems.append(contentsOf: list)
            } catch {
                // 개별 월 실패는 무시하고 계속 진행
            }
        }
        monthAlbums = allItems
        isLoading = false
    }

    func loadDetail(albumId: Int) async {
        do {
            let list = try await AlbumService.shared.fetchAlbumDetail(albumId: albumId)
            detailCache[albumId] = list
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 특정 albumId 의 상세 데이터를 DailyAlbumData(photos 포함) 형식으로 로드.
    /// 캘린더에서 과거 날짜 탭 시 사용.
    func loadAlbumById(_ albumId: Int) async {
        isLoading = true
        do {
            let data = try await AlbumService.shared.fetchAlbumAsDaily(albumId: albumId)
            selectedDateAlbum = data
        } catch {
            print("[PhotoStore] albumId=\(albumId) 상세 로드 실패: \(error)")
            selectedDateAlbum = nil
        }
        isLoading = false
    }

    /// 특정 날짜의 앨범에서 슬롯별 사진 조회 (selectedDateAlbum 기반)
    func selectedDatePhoto(for slot: AlbumSlot) -> PhotoData? {
        selectedDateAlbum?.photos.first { $0.type == slot.albumType.rawValue }
    }

    /// 특정 날짜 앨범의 사진 수
    var selectedDatePhotoCount: Int {
        selectedDateAlbum?.photoCount ?? selectedDateAlbum?.photos.count ?? 0
    }

    /// monthAlbums 또는 calendarCache 에서 해당 날짜의 albumId 찾기
    func albumId(for date: Date) -> Int? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        // monthAlbums 먼저 확인, 없으면 calendarCache 에서 조회
        return monthAlbums.first { $0.albumDate == dateString }?.albumId
            ?? calendarCache[dateString]?.albumId
    }

    // MARK: - 업로드

    /// 카메라에서 저장하기 눌렀을 때 호출.
    /// 시간대와 오늘 앨범 상태를 보고 알맞은 type 을 결정해서 업로드한 뒤 today 를 새로고침한다.
    func uploadPhoto(front: UIImage, back: UIImage, capturedAt: Date) async throws {
        let type = nextAvailableType(at: capturedAt)
        guard let type = type else {
            throw AlbumError.serverError("앨범이 가득 찼습니다 (5/5)")
        }
        _ = try await AlbumService.shared.upload(front: front, back: back, type: type)
        await loadToday()
        // publish는 여기서 하지 않음 — 게시하기 버튼(PublishPreviewView)에서만 호출
        // publish가 호출되면 피드 게시 + 스토리 공개가 동시에 처리됨
    }

    // MARK: - 슬롯 자동 결정

    /// 촬영 시각의 기본 시간대 슬롯이 비어있으면 그 슬롯, 차있거나 추가 시간대면 FREE_1 → FREE_2 순으로 결정.
    /// 모두 차있으면 nil 반환.
    private func nextAvailableType(at date: Date) -> AlbumType? {
        let timeSlot = TimeSlot.from(date: date)
        let usedTypes: Set<String> = Set(todayAlbum?.photos.map { $0.type } ?? [])

        // 메인 시간대이고 해당 슬롯이 비어있으면 배정
        if let primarySlot = timeSlot.albumSlot {
            let primary = primarySlot.albumType
            if !usedTypes.contains(primary.rawValue) {
                return primary
            }
        }

        // 메인 슬롯이 차있거나 추가 시간대면 FREE_1 → FREE_2
        if !usedTypes.contains(AlbumType.free1.rawValue) {
            return .free1
        }
        if !usedTypes.contains(AlbumType.free2.rawValue) {
            return .free2
        }
        return nil
    }

    // MARK: - 게시 가능 여부

    /// 게시 성공 후 로컬 마킹 (오늘 날짜 기준, UserDefaults 영구 저장)
    /// 날짜가 바뀌면 자동으로 리셋됨
    @Published private(set) var publishedAlbumIds: Set<Int> = []
    private var publishedLoaded = false

    private let publishedKey = "publishedAlbumIds"
    private let publishedDateKey = "publishedAlbumDate"

    /// 앱 시작 시 또는 loadToday() 후 호출하여 게시 상태를 미리 로드
    func loadPublishedState() {
        let today = todayString()
        let savedDate = UserDefaults.standard.string(forKey: publishedDateKey) ?? ""
        if savedDate != today {
            publishedAlbumIds = []
            UserDefaults.standard.set(today, forKey: publishedDateKey)
            UserDefaults.standard.set([Int](), forKey: publishedKey)
        } else {
            let saved = UserDefaults.standard.array(forKey: publishedKey) as? [Int] ?? []
            publishedAlbumIds = Set(saved)
        }
        publishedLoaded = true
    }

    /// 이 앨범을 이미 게시했는지 
    func hasPublished(albumId: Int) -> Bool {
        if !publishedLoaded { loadPublishedState() }
        return publishedAlbumIds.contains(albumId)
    }

    /// 게시 성공 시 호출
    func markPublished(albumId: Int) {
        if !publishedLoaded { loadPublishedState() }
        publishedAlbumIds.insert(albumId)
        savePublished()
    }

    private func savePublished() {
        UserDefaults.standard.set(Array(publishedAlbumIds), forKey: publishedKey)
        UserDefaults.standard.set(todayString(), forKey: publishedDateKey)
    }

    private func todayString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "Asia/Seoul")
        return fmt.string(from: Date())
    }

    // MARK: - 촬영 가능 여부

    /// 지금 사진을 찍을 수 있으면 nil, 없으면 안내 메시지 반환
    func cannotTakePhotoMessage() -> String? {
        let usedTypes = Set(todayAlbum?.photos.map { $0.type } ?? [])
        print("[PhotoStore] cannotTakePhotoMessage - todayAlbum=\(todayAlbum != nil), usedTypes=\(usedTypes)")

        // 슬롯이 남아있으면 촬영 가능
        if nextAvailableType(at: Date()) != nil { return nil }

        // 다음 시간대 안내
        let timeSlot = TimeSlot.current
        switch timeSlot {
        case .morning:
            return "점심 시간(12:00)에 사진이 활성화 됩니다!"
        case .afternoon:
            return "저녁 시간(17:00)에 사진이 활성화 됩니다!"
        case .evening:
            return "내일 아침(06:00)에 사진이 활성화 됩니다!"
        case .extra:
            let hour = Calendar.current.component(.hour, from: Date())
            if hour < 6 {
                return "아침 시간(06:00)에 사진이 활성화 됩니다!"
            } else if hour < 12 {
                return "점심 시간(12:00)에 사진이 활성화 됩니다!"
            } else {
                return "저녁 시간(17:00)에 사진이 활성화 됩니다!"
            }
        }
    }

    // MARK: - 헬퍼

    /// 오늘 앨범에서 특정 슬롯에 해당하는 사진
    func todayPhoto(for slot: AlbumSlot) -> PhotoData? {
        todayAlbum?.photos.first { $0.type == slot.albumType.rawValue }
    }

    /// 오늘 앨범의 사진 수
    var todayPhotoCount: Int {
        todayAlbum?.photoCount ?? 0
    }
}
