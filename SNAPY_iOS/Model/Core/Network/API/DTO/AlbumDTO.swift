//
//  AlbumDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/9/26.
//

import Foundation

// MARK: - 서버 type enum

enum AlbumType: String, Codable, CaseIterable {
    case morning   = "MORNING"
    case afternoon = "LUNCH"
    case evening   = "DINNER"
    case free1     = "FREE_1"
    case free2     = "FREE_2"

    /// 클라이언트의 5칸 슬롯과 매핑
    var albumSlot: AlbumSlot {
        switch self {
        case .morning:   return .morning
        case .afternoon: return .afternoon
        case .evening:   return .evening
        case .free1:     return .extra1
        case .free2:     return .extra2
        }
    }
}

extension AlbumSlot {
    var albumType: AlbumType {
        switch self {
        case .morning:   return .morning
        case .afternoon: return .afternoon
        case .evening:   return .evening
        case .extra1:    return .free1
        case .extra2:    return .free2
        }
    }
}

// MARK: - 응답 DTO

/// 데일리 앨범 안의 사진 한 칸 (today / detail 응답에서 사용)
struct PhotoData: Codable, Identifiable {
    let type: String
    let frontImageUrl: String?
    let backImageUrl: String?
    let createdAt: String?      // "2026-04-15T11:16:23.050Z"

    var id: String { type }

    private enum CodingKeys: String, CodingKey {
        case type, frontImageUrl, backImageUrl, createdAt
    }

    var albumType: AlbumType? { AlbumType(rawValue: type) }
    var albumSlot: AlbumSlot? { albumType?.albumSlot }

    /// 촬영 시각을 "11시 16분" 형태로 반환. 없으면 nil.
    var capturedTimeText: String? {
        guard let createdAt = createdAt else { return nil }
        // ISO8601 파싱 시도
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: createdAt) {
            let tf = DateFormatter()
            tf.dateFormat = "HH시 mm분"
            tf.locale = Locale(identifier: "ko_KR")
            return tf.string(from: date)
        }
        // "T" 기준으로 시간 부분만 추출 시도
        if let timepart = createdAt.split(separator: "T").last {
            let hhmm = String(timepart.prefix(5))  // "09:30"
            let parts = hhmm.split(separator: ":")
            if parts.count == 2 {
                return "\(parts[0])시 \(parts[1])분"
            }
        }
        return nil
    }
}

/// 데일리 앨범 (today 응답)
struct DailyAlbumData: Codable {
    let albumId: Int
    let albumDate: String
    let photoCount: Int
    let photos: [PhotoData]
}

/// 월간 목록 / 디테일 응답 항목 (썸네일만)
struct AlbumListItemData: Codable, Identifiable {
    let albumId: Int
    let albumDate: String
    let thumbnailUrl: String?

    var id: Int { albumId }
}

/// 업로드 응답 data
struct AlbumUploadData: Codable {
    let albumId: Int
    let albumDate: String
    let type: String
    let photoCount: Int
}

// MARK: - typealias

typealias AlbumUploadResponse = BaseResponse<AlbumUploadData>
typealias TodayAlbumResponse  = BaseResponse<DailyAlbumData>
typealias AlbumListResponse   = BaseResponse<[AlbumListItemData]>
typealias AlbumDetailResponse = BaseResponse<[AlbumListItemData]>
