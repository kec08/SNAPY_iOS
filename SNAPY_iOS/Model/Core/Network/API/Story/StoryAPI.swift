//
//  StoryAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/19/26.
//

import Foundation
import Moya
internal import Alamofire

enum StoryAPI {
    case fetchStories                                    // GET  /api/stories
    case fetchDetail(storyId: Int)                       // GET  /api/stories/{storyId}
    case toggleLike(storyId: Int, type: AlbumType)       // POST /api/stories/{storyId}/photos/{type}/likes
    case fetchLikes(storyId: Int, type: AlbumType)       // GET  /api/stories/{storyId}/photos/{type}/likes
}

extension StoryAPI: TargetType {

    var baseURL: URL {
        URL(string: "http://3.36.111.255:8080")!
    }

    var path: String {
        switch self {
        case .fetchStories:
            return "/api/stories"
        case .fetchDetail(let storyId):
            return "/api/stories/\(storyId)"
        case .toggleLike(let storyId, let type):
            return "/api/stories/\(storyId)/photos/\(type.rawValue)/likes"
        case .fetchLikes(let storyId, let type):
            return "/api/stories/\(storyId)/photos/\(type.rawValue)/likes"
        }
    }

    var method: Moya.Method {
        switch self {
        case .fetchStories, .fetchDetail, .fetchLikes:
            return .get
        case .toggleLike:
            return .post
        }
    }

    var task: Moya.Task {
        .requestPlain
    }

    var headers: [String: String]? {
        var h: [String: String] = ["Content-Type": "application/json"]
        if let token = TokenStorage.accessToken {
            h["Authorization"] = "Bearer \(token)"
        }
        return h
    }
}
