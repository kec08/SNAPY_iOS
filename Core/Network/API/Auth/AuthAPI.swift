//
//  AuthAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/25/25.
//

import Foundation
import Moya
internal import Alamofire

enum AuthAPI {
    case login(email: String, password: String)
    case signup(username: String, handle: String, email: String, phone: String, password: String)
    case refresh
    case logout
}

extension AuthAPI: TargetType {

    var baseURL: URL {
        // 백엔드 주소
        return URL(string: "http://")!
    }

    var path: String {
        switch self {
        case .login:
            return "/api/auth/login"
        case .signup:
            return "/api/auth/register"
        case .refresh:
            return "/api/refresh-accesstoken"
        case .logout:
            return "/api/auth/logout"
        }
    }

    var method: Moya.Method {
        return .post
    }

    var task: Task {
        switch self {
        case let .login(email, password):
            let params: [String: Any] = [
                "email": email,
                "password": password
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case let .signup(username, handle, email, phone, password):
            let params: [String: Any] = [
                "username": username,
                "handle": handle,
                "email": email,
                "phone": phone,
                "password": password
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case .refresh:
            // RefreshToken은 쿠키에서 서버가 자동 추출
            return .requestPlain

        case .logout:
            return .requestPlain
        }
    }

    var headers: [String : String]? {
        switch self {
        case .login, .signup:
            return ["Content-Type": "application/json"]

        case .refresh:
            // RefreshToken은 쿠키에 자동으로 심어져 있으므로 별도 헤더 불필요
            return ["Content-Type": "application/json"]

        case .logout:
            var headers: [String: String] = [
                "Content-Type": "application/json"
            ]
            if let access = TokenStorage.accessToken {
                headers["Authorization"] = "Bearer \(access)"
            }
            return headers
        }
    }
}
