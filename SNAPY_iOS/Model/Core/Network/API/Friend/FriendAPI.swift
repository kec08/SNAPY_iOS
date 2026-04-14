//
//  FriendAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/14/26.
//

import Foundation
import Moya
internal import Alamofire

enum FriendAPI {
    case sendRequest(handle: String)                        // POST   /api/friend-requests/{handle}
    case cancelRequest(handle: String)                      // DELETE /api/friend-requests/{handle}
    case getReceivedRequests                                // GET    /api/friend-requests/received
    case processRequest(requestId: Int, action: FriendRequestAction) // PATCH  /api/friend-requests/{requestId}
    case getRequestStatus(handle: String)                   // GET    /api/friend-requests/{handle}
    case removeFriend(handle: String)                       // DELETE /api/friends/{handle}
    case getRecommendedFriends                              // GET    /api/users/me/recommended-friends
    case searchUsers(query: String)                         // GET    /api/users?q=
}

extension FriendAPI: TargetType {

    var baseURL: URL {
        return URL(string: "http://3.36.111.255:8080")!
    }

    var path: String {
        switch self {
        case .sendRequest(let handle), .cancelRequest(let handle), .getRequestStatus(let handle):
            return "/api/friend-requests/\(handle)"
        case .getReceivedRequests:
            return "/api/friend-requests/received"
        case .processRequest(let requestId, _):
            return "/api/friend-requests/\(requestId)"
        case .removeFriend(let handle):
            return "/api/friends/\(handle)"
        case .getRecommendedFriends:
            return "/api/users/me/recommended-friends"
        case .searchUsers:
            return "/api/users"
        }
    }

    var method: Moya.Method {
        switch self {
        case .sendRequest:
            return .post
        case .cancelRequest, .removeFriend:
            return .delete
        case .getReceivedRequests, .getRequestStatus, .getRecommendedFriends, .searchUsers:
            return .get
        case .processRequest:
            return .patch
        }
    }

    var task: Moya.Task {
        switch self {
        case .processRequest(_, let action):
            let body = FriendRequestActionBody(action: action.rawValue)
            return .requestJSONEncodable(body)
        case .searchUsers(let query):
            return .requestParameters(parameters: ["q": query], encoding: URLEncoding.queryString)
        default:
            return .requestPlain
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
