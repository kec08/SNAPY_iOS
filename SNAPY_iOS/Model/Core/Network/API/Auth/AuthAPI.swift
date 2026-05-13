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
    case signup(username: String, handle: String, email: String, password: String)
    case googleLogin(idToken: String)
    case appleLogin(identityToken: String, fullName: String?)
    case refresh
    case logout
    case deleteAccount
}

extension AuthAPI: TargetType {

    var baseURL: URL {
        // 백엔드 주소
        return URL(string: "https://snapy.api.krafte.net")!
    }

    var path: String {
        switch self {
        case .login:
            return "/api/auth/login"
        case .signup:
            return "/api/auth/register"
        case .googleLogin:
            return "/api/auth/google/ios"
        case .appleLogin:
            return "/api/auth/apple/ios"
        case .refresh:
            return "/api/auth/refresh-accesstoken"
        case .logout:
            return "/api/auth/logout"
        case .deleteAccount:
            return "/api/users/me"
        }
    }

    var method: Moya.Method {
        switch self {
        case .deleteAccount:
            return .delete
        default:
            return .post
        }
    }

    var task: Task {
        switch self {
        case let .login(email, password):
            let params: [String: Any] = [
                "email": email,
                "password": password
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case let .signup(username, handle, email, password):
            let params: [String: Any] = [
                "username": username,
                "handle": handle,
                "email": email,
                "password": password
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case let .googleLogin(idToken):
            let params: [String: Any] = [
                "idToken": idToken
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case let .appleLogin(identityToken, fullName):
            var params: [String: Any] = [
                "identityToken": identityToken
            ]
            if let fullName { params["fullName"] = fullName }
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)

        case .refresh:
            // RefreshToken은 쿠키에서 서버가 자동 추출
            return .requestPlain

        case .logout, .deleteAccount:
            return .requestPlain
        }
    }

    var headers: [String : String]? {
        switch self {
        case .login, .signup, .googleLogin, .appleLogin:
            return [
                "Content-Type": "application/json",
                "X-Client-Type": "app"
            ]

        case .refresh:
            var headers: [String: String] = [
                "Content-Type": "application/json",
                "X-Client-Type": "app"
            ]
            if let refresh = TokenStorage.refreshToken {
                headers["X-Refresh-Token"] = refresh
            }
            return headers

        case .logout, .deleteAccount:
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
