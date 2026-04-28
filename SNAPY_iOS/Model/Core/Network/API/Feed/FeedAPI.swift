//
//  FeedAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/28/26.
//

import Foundation
import Moya
internal import Alamofire

enum FeedAPI {
    case recommend(cursor: Int?, size: Int)   // GET /api/feed
}

extension FeedAPI: TargetType {

    var baseURL: URL {
        URL(string: "http://3.36.111.255:8080")!
    }

    var path: String {
        switch self {
        case .recommend:
            return "/api/feed"
        }
    }

    var method: Moya.Method {
        switch self {
        case .recommend:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case .recommend(let cursor, let size):
            var params: [String: Any] = ["size": size]
            if let cursor { params["cursor"] = cursor }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
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
