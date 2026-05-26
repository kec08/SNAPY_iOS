//
//  ReportAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/26/26.
//

import Foundation
import Moya
internal import Alamofire

enum ReportAPI {
    case create(targetType: String, targetId: Int64?, userHandle: String?, reason: String)  // POST /api/reports
}

extension ReportAPI: TargetType {

    var baseURL: URL {
        return URL(string: "https://snapy.api.krafte.net")!
    }

    var path: String {
        switch self {
        case .create:
            return "/api/reports"
        }
    }

    var method: Moya.Method {
        switch self {
        case .create:
            return .post
        }
    }

    var task: Moya.Task {
        switch self {
        case .create(let targetType, let targetId, let userHandle, let reason):
            var body: [String: Any] = [
                "targetType": targetType,
                "reason": reason
            ]
            if let targetId { body["targetId"] = targetId }
            if let userHandle { body["userHandle"] = userHandle }
            return .requestParameters(parameters: body, encoding: JSONEncoding.default)
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
