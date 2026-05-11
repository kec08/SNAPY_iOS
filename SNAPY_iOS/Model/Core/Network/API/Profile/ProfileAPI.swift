//
//  ProfileAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import Foundation
import Moya
internal import Alamofire
import UIKit

enum ProfileAPI {
    case fetchMyProfile                                  // GET  /api/users/me
    case fetchUserProfile(handle: String)                // GET  /api/users/{handle}
    case updateProfileImage(image: UIImage)               // PATCH /api/users/me/profile-image
    case updateBackgroundImage(image: UIImage)             // PATCH /api/users/me/background-image
    case fetchSettings                                   // GET  /api/users/me/settings
    case updateFeedVisibility(Visibility)                 // PATCH /api/users/me/settings/feed-visibility
    case updatePastAlbumVisibility(Visibility)            // PATCH /api/users/me/settings/past-album-visibility
    case fetchGuestbook(handle: String)                  // GET  /api/users/{handle}/guestbook
    case postGuestbook(handle: String, image: UIImage)   // POST /api/users/{handle}/guestbook
    case updatePhone(phone: String)                      // PATCH /api/users/me/phone
    case updateHandle(handle: String)                    // PATCH /api/users/me/handle
    case updateUsername(username: String)                 // PATCH /api/users/me/username
    case checkHandle(handle: String)                     // GET   /api/users/handle/check
}

extension ProfileAPI: TargetType {

    var baseURL: URL {
        return URL(string: "https://snapy.api.krafte.net")!
    }

    var path: String {
        switch self {
        case .fetchMyProfile:
            return "/api/users/me"
        case .fetchUserProfile(let handle):
            return "/api/users/\(handle)"
        case .updateProfileImage:
            return "/api/users/me/profile-image"
        case .updateBackgroundImage:
            return "/api/users/me/background-image"
        case .fetchSettings:
            return "/api/users/me/settings"
        case .updateFeedVisibility:
            return "/api/users/me/settings/feed-visibility"
        case .updatePastAlbumVisibility:
            return "/api/users/me/settings/past-album-visibility"
        case .fetchGuestbook(let handle):
            return "/api/users/\(handle)/guestbook"
        case .postGuestbook(let handle, _):
            return "/api/users/\(handle)/guestbook"
        case .updatePhone:
            return "/api/users/me/phone"
        case .updateHandle:
            return "/api/users/me/handle"
        case .updateUsername:
            return "/api/users/me/username"
        case .checkHandle:
            return "/api/users/handle/check"
        }
    }

    var method: Moya.Method {
        switch self {
        case .fetchMyProfile, .fetchUserProfile, .fetchSettings, .fetchGuestbook, .checkHandle:
            return .get
        case .postGuestbook:
            return .post
        case .updateProfileImage, .updateBackgroundImage,
             .updateFeedVisibility, .updatePastAlbumVisibility, .updatePhone,
             .updateHandle, .updateUsername:
            return .patch
        }
    }

    var task: Moya.Task {
        switch self {
        case .fetchMyProfile, .fetchUserProfile, .fetchSettings, .fetchGuestbook:
            return .requestPlain

        case .checkHandle(let handle):
            return .requestParameters(
                parameters: ["handle": handle],
                encoding: URLEncoding.queryString
            )

        case .postGuestbook(let handle, let image):
            let imageData = image.jpegData(compressionQuality: 0.85) ?? Data()
            print("[ProfileAPI] 방명록 POST - handle: \(handle)")
            print("[ProfileAPI] 방명록 POST - imageData size: \(imageData.count) bytes")
            let formData = Moya.MultipartFormData(
                provider: .data(imageData),
                name: "image",
                fileName: "image.jpg",
                mimeType: "image/jpeg"
            )
            return .uploadMultipart([formData])

        case .updateProfileImage(let image), .updateBackgroundImage(let image):
            let imageData = image.jpegData(compressionQuality: 0.85) ?? Data()
            let formData = Moya.MultipartFormData(
                provider: .data(imageData),
                name: "image",
                fileName: "image.jpg",
                mimeType: "image/jpeg"
            )
            return .uploadMultipart([formData])

        case .updateFeedVisibility(let v):
            let body = UpdateVisibilityRequest(visibility: v.rawValue)
            return .requestJSONEncodable(body)
        case .updatePastAlbumVisibility(let v):
            let body = UpdateVisibilityRequest(visibility: v.rawValue)
            return .requestJSONEncodable(body)
        case .updatePhone(let phone):
            return .requestParameters(
                parameters: ["phone": phone],
                encoding: JSONEncoding.default
            )
        case .updateHandle(let handle):
            return .requestParameters(
                parameters: ["handle": handle],
                encoding: JSONEncoding.default
            )
        case .updateUsername(let username):
            return .requestParameters(
                parameters: ["username": username],
                encoding: JSONEncoding.default
            )
        }
    }

    var headers: [String: String]? {
        var h: [String: String] = [:]

        switch self {
        case .updateProfileImage, .updateBackgroundImage, .postGuestbook:
            break // multipart Content-Type 은 Moya 가 자동 설정
        default:
            h["Content-Type"] = "application/json"
        }

        if let token = TokenStorage.accessToken {
            h["Authorization"] = "Bearer \(token)"
        }
        return h
    }
}
