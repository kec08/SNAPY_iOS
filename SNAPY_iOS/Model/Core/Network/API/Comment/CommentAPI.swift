//
//  CommentAPI.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/2/26.
//

import Foundation
import Moya
internal import Alamofire

enum CommentAPI {
    case fetchComments(albumId: Int, cursor: Int?, size: Int)
    case uploadEmoji(albumId: Int, emoji: String)
    case uploadImage(albumId: Int, imageData: Data)
    case uploadAudio(albumId: Int, audioData: Data)
    case delete(commentId: Int)
}

extension CommentAPI: TargetType {

    var baseURL: URL {
        URL(string: "http://3.36.111.255:8080")!
    }

    var path: String {
        switch self {
        case .fetchComments(let albumId, _, _):
            return "/api/albums/\(albumId)/comments"
        case .uploadEmoji(let albumId, _),
             .uploadImage(let albumId, _),
             .uploadAudio(let albumId, _):
            return "/api/albums/\(albumId)/comments"
        case .delete(let commentId):
            return "/api/comments/\(commentId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .fetchComments:
            return .get
        case .uploadEmoji, .uploadImage, .uploadAudio:
            return .post
        case .delete:
            return .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case .fetchComments(_, let cursor, let size):
            var params: [String: Any] = ["size": size]
            if let cursor { params["cursor"] = cursor }
            return .requestParameters(parameters: params, encoding: URLEncoding.queryString)

        case .uploadEmoji(_, let emoji):
            let formData: [Moya.MultipartFormData] = [
                Moya.MultipartFormData(
                    provider: .data("EMOJI".data(using: .utf8)!),
                    name: "type"
                ),
                Moya.MultipartFormData(
                    provider: .data(emoji.data(using: .utf8)!),
                    name: "emojiValue"
                )
            ]
            return .uploadMultipart(formData)

        case .uploadImage(_, let imageData):
            let formData: [Moya.MultipartFormData] = [
                Moya.MultipartFormData(
                    provider: .data("IMAGE".data(using: .utf8)!),
                    name: "type"
                ),
                Moya.MultipartFormData(
                    provider: .data(imageData),
                    name: "file",
                    fileName: "comment.jpg",
                    mimeType: "image/jpeg"
                )
            ]
            return .uploadMultipart(formData)

        case .uploadAudio(_, let audioData):
            let formData: [Moya.MultipartFormData] = [
                Moya.MultipartFormData(
                    provider: .data("AUDIO".data(using: .utf8)!),
                    name: "type"
                ),
                Moya.MultipartFormData(
                    provider: .data(audioData),
                    name: "file",
                    fileName: "comment.m4a",
                    mimeType: "audio/m4a"
                )
            ]
            return .uploadMultipart(formData)

        case .delete:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        var h: [String: String] = [:]
        switch self {
        case .uploadEmoji, .uploadImage, .uploadAudio:
            break // multipart → Moya가 Content-Type 자동 설정
        default:
            h["Content-Type"] = "application/json"
        }
        if let token = TokenStorage.accessToken {
            h["Authorization"] = "Bearer \(token)"
        }
        return h
    }
}
