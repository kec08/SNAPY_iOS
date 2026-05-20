//
//  BlockAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/20/26.
//

import Foundation
import Moya
internal import Alamofire

enum BlockAPI {
    case blockUser(handle: String)       // POST   /api/blocks/{handle}
    case unblockUser(handle: String)     // DELETE /api/blocks/{handle}
    case getBlockedUsers                 // GET    /api/blocks
}

extension BlockAPI: TargetType {

    var baseURL: URL {
        return URL(string: "https://snapy.api.krafte.net")!
    }

    var path: String {
        switch self {
        case .blockUser(let handle), .unblockUser(let handle):
            return "/api/blocks/\(handle)"
        case .getBlockedUsers:
            return "/api/blocks"
        }
    }

    var method: Moya.Method {
        switch self {
        case .blockUser:
            return .post
        case .unblockUser:
            return .delete
        case .getBlockedUsers:
            return .get
        }
    }

    var task: Moya.Task {
        return .requestPlain
    }

    var headers: [String: String]? {
        var h: [String: String] = ["Content-Type": "application/json"]
        if let token = TokenStorage.accessToken {
            h["Authorization"] = "Bearer \(token)"
        }
        return h
    }
}
