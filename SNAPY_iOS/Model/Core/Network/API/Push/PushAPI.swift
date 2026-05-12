//
//  PushAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/12/26.
//

import Foundation
import Moya
internal import Alamofire

enum PushAPI {
    case registerToken(token: String, environment: String)  // POST /api/device-tokens
    case deleteToken(token: String)                          // DELETE /api/device-tokens
}

extension PushAPI: TargetType {

    var baseURL: URL {
        URL(string: "https://snapy.api.krafte.net")!
    }

    var path: String {
        switch self {
        case .registerToken, .deleteToken:
            return "/api/device-tokens"
        }
    }

    var method: Moya.Method {
        switch self {
        case .registerToken:
            return .post
        case .deleteToken:
            return .delete
        }
    }

    var task: Task {
        switch self {
        case .registerToken(let token, let environment):
            let params: [String: Any] = [
                "token": token,
                "platform": "IOS",
                "environment": environment
            ]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .deleteToken(let token):
            let params: [String: Any] = ["token": token]
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }

    var headers: [String: String]? {
        var h: [String: String] = ["Content-Type": "application/json"]
        if let token = TokenStorage.accessToken {
            h["Authorization"] = "Bearer \(token)"
        }
        return h
    }
}
