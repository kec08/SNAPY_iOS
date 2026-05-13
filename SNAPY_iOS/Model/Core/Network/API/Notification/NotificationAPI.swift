//
//  NotificationAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import Foundation
import Moya
internal import Alamofire

enum NotificationAPI {
    case getNotifications(page: Int, size: Int)
    case getUnreadCount
    case markAsRead(id: Int64)
    case markAllAsRead
}

extension NotificationAPI: TargetType {

    var baseURL: URL {
        URL(string: "http://3.36.67.129:8080")!
    }

    var path: String {
        switch self {
        case .getNotifications:
            return "/api/notifications"
        case .getUnreadCount:
            return "/api/notifications/unread-count"
        case .markAsRead(let id):
            return "/api/notifications/\(id)/read"
        case .markAllAsRead:
            return "/api/notifications/read-all"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getNotifications, .getUnreadCount:
            return .get
        case .markAsRead, .markAllAsRead:
            return .patch
        }
    }

    var task: Task {
        switch self {
        case .getNotifications(let page, let size):
            let params: [String: Any] = ["page": page, "size": size]
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)
        case .getUnreadCount, .markAsRead, .markAllAsRead:
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
