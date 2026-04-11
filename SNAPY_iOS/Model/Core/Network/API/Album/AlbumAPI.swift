//
//  AlbumAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/9/26.
//

import Foundation
import UIKit
import Moya
internal import Alamofire

enum AlbumAPI {
    case upload(front: UIImage, back: UIImage, type: AlbumType)
    case fetchToday
    case fetchByMonth(month: Int)
    case fetchDetail(albumId: Int)
}

extension AlbumAPI: TargetType {

    var baseURL: URL {
        return URL(string: "http://3.36.111.255:8080")!
    }

    var path: String {
        switch self {
        case .upload:
            return "/api/albums"
        case .fetchToday:
            return "/api/albums/today"
        case .fetchByMonth:
            return "/api/albums"
        case .fetchDetail(let albumId):
            return "/api/albums/\(albumId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .upload:
            return .post
        case .fetchToday, .fetchByMonth, .fetchDetail:
            return .get
        }
    }

    var task: Moya.Task {
        switch self {
        case let .upload(front, back, type):
            let frontData = front.jpegData(compressionQuality: 0.85) ?? Data()
            let backData  = back.jpegData(compressionQuality: 0.85)  ?? Data()

            let parts: [Moya.MultipartFormData] = [
                Moya.MultipartFormData(
                    provider: .data(frontData),
                    name: "frontImage",
                    fileName: "front.jpg",
                    mimeType: "image/jpeg"
                ),
                Moya.MultipartFormData(
                    provider: .data(backData),
                    name: "backImage",
                    fileName: "back.jpg",
                    mimeType: "image/jpeg"
                ),
                Moya.MultipartFormData(
                    provider: .data(type.rawValue.data(using: .utf8) ?? Data()),
                    name: "type"
                )
            ]
            return .uploadMultipart(parts)

        case .fetchByMonth(let month):
            return .requestParameters(
                parameters: ["month": month],
                encoding: URLEncoding.queryString
            )

        case .fetchToday, .fetchDetail:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        var h: [String: String] = [:]

        switch self {
        case .upload:
            // multipart 의 Content-Type 은 Moya 가 boundary 와 함께 자동 설정하므로
            // 여기서는 명시하지 않는다.
            break
        default:
            h["Content-Type"] = "application/json"
        }

        if let token = TokenStorage.accessToken {
            h["Authorization"] = "Bearer \(token)"
        }
        return h
    }
}
