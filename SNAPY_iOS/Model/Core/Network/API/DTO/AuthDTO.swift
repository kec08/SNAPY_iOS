//
//  AuthDTO.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/25/25.
//

import Foundation

// Base Response
struct BaseResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String
}

// 회원가입 Request
struct SignUpRequest: Codable {
    let username: String
    let handle: String
    let email: String
    let phone: String
    let password: String
}

// 회원가입 Response
struct SignUpData: Codable {
    let handle: String
    let username: String
    let email: String?
}

typealias SignUpResponse = BaseResponse<SignUpData>

// 로그인 Request
struct LoginRequest: Codable {
    let email: String
    let password: String
}

// 로그인 Response Data
struct LoginData: Codable {
    let accessToken: String
    let refreshToken: String?
}

typealias LoginResponse = BaseResponse<LoginData>

// 토큰 재발급 Response
typealias RefreshResponse = BaseResponse<LoginData>

// 로그아웃 Response
typealias LogoutResponse = BaseResponse<EmptyData>

// data가 null일 떄 사용
struct EmptyData: Codable {}
