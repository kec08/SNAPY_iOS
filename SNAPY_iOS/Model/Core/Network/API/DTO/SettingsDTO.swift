//
//  SettingsDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/20/26.
//

import Foundation

// MARK: - 공개 범위

enum Visibility: String, Codable {
    case publicAll   = "PUBLIC"
    case friendsOnly = "FRIENDS_ONLY"
    case onlyMe      = "ONLY_ME"
}

// MARK: - 설정 조회 응답

struct UserSettingData: Codable {
    let feedVisibility: String
    let pastAlbumVisibility: String

    var feedVisibilityEnum: Visibility {
        Visibility(rawValue: feedVisibility) ?? .friendsOnly
    }

    var pastAlbumVisibilityEnum: Visibility {
        Visibility(rawValue: pastAlbumVisibility) ?? .friendsOnly
    }
}

// MARK: - 설정 변경 요청

struct UpdateVisibilityRequest: Codable {
    let visibility: String
}

// MARK: - typealias

typealias UserSettingResponse = BaseResponse<UserSettingData>
