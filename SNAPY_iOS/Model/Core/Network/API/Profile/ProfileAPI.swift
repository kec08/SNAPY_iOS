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
    case fetchMyProfile                                  // GET  /api/users/me/profile
    case fetchUserProfile(handle: String)                // GET  /api/users/{handle}/profile
    case updateProfileImage(image: UIImage)               // PATCH /api/users/me/profile-image
    case updateBackgroundImage(image: UIImage)             // PATCH /api/users/me/background-image
}

extension ProfileAPI: TargetType {

    var baseURL: URL {
        return URL(string: "http://3.36.111.255:8080")!
    }

    var path: String {
        switch self {
        case .fetchMyProfile:
            return "/api/users/me"
        case .fetchUserProfile(let handle):
            return "/api/users/\(handle)/profile"
        case .updateProfileImage:
            return "/api/users/me/profile-image"
        case .updateBackgroundImage:
            return "/api/users/me/background-image"
        }
    }

    var method: Moya.Method {
        switch self {
        case .fetchMyProfile, .fetchUserProfile:
            return .get
        case .updateProfileImage, .updateBackgroundImage:
            return .patch
        }
    }

    var task: Moya.Task {
        switch self {
        case .fetchMyProfile, .fetchUserProfile:
            return .requestPlain

        case .updateProfileImage(let image), .updateBackgroundImage(let image):
            let imageData = image.jpegData(compressionQuality: 0.85) ?? Data()
            let formData = Moya.MultipartFormData(
                provider: .data(imageData),
                name: "image",
                fileName: "image.jpg",
                mimeType: "image/jpeg"
            )
            return .uploadMultipart([formData])
        }
    }

    var headers: [String: String]? {
        var h: [String: String] = [:]

        switch self {
        case .updateProfileImage, .updateBackgroundImage:
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
