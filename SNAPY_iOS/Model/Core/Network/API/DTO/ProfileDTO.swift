//
//  ProfileDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import Foundation

// MARK: - 내 프로필 / 타인 프로필 조회 응답

struct ProfileData: Codable {
    let handle: String
    let username: String
    let profileImageUrl: String?
    let backgroundImageUrl: String?
}

typealias ProfileResponse = BaseResponse<ProfileData>

// MARK: - 프로필 이미지 변경 응답

struct ProfileImageData: Codable {
    let profileImageUrl: String?
}

typealias ProfileImageResponse = BaseResponse<ProfileImageData>

// MARK: - 배경 이미지 변경 응답

struct BackgroundImageData: Codable {
    let backgroundImageUrl: String?
}

typealias BackgroundImageResponse = BaseResponse<BackgroundImageData>
