//
//  CommentService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/2/26.
//

import Foundation
import Moya
import UIKit

enum CommentError: Error, LocalizedError {
    case unauthorized
    case serverError(String)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .unauthorized:         return "로그인이 필요합니다."
        case .serverError(let msg): return msg
        case .decodingFailed:       return "응답을 해석할 수 없습니다."
        }
    }
}

final class CommentService {
    static let shared = CommentService()
    private let provider = MoyaProvider<CommentAPI>()

    private init() {}

    // MARK: - 댓글 목록 조회

    func fetchComments(albumId: Int, cursor: Int? = nil, size: Int = 20) async throws -> CursorResponse<CommentResponseData> {
        let response = try await requestWithRefresh(.fetchComments(albumId: albumId, cursor: cursor, size: size))
        guard (200..<300).contains(response.statusCode) else {
            throw CommentError.serverError("서버 오류 (\(response.statusCode))")
        }
        let decoded = try JSONDecoder().decode(CommentListResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw CommentError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 이모지 댓글 작성

    func uploadEmoji(albumId: Int, emoji: String) async throws -> CommentUploadResponseData {
        let response = try await requestWithRefresh(.uploadEmoji(albumId: albumId, emoji: emoji))
        guard (200..<300).contains(response.statusCode) else {
            throw CommentError.serverError("서버 오류 (\(response.statusCode))")
        }
        let decoded = try JSONDecoder().decode(CommentUploadResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw CommentError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 이미지 댓글 작성

    func uploadImage(albumId: Int, image: UIImage) async throws -> CommentUploadResponseData {
        let resized = Self.resizeImage(image, maxDimension: 1024)
        guard let imageData = resized.jpegData(compressionQuality: 0.7) else {
            throw CommentError.serverError("이미지 변환 실패")
        }
        let response = try await requestWithRefresh(.uploadImage(albumId: albumId, imageData: imageData))
        guard (200..<300).contains(response.statusCode) else {
            throw CommentError.serverError("서버 오류 (\(response.statusCode))")
        }
        let decoded = try JSONDecoder().decode(CommentUploadResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw CommentError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 음성 댓글 작성

    func uploadAudio(albumId: Int, audioURL: URL) async throws -> CommentUploadResponseData {
        let audioData = try Data(contentsOf: audioURL)
        let response = try await requestWithRefresh(.uploadAudio(albumId: albumId, audioData: audioData))
        guard (200..<300).contains(response.statusCode) else {
            throw CommentError.serverError("서버 오류 (\(response.statusCode))")
        }
        let decoded = try JSONDecoder().decode(CommentUploadResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw CommentError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 댓글 삭제

    func deleteComment(commentId: Int) async throws {
        let response = try await requestWithRefresh(.delete(commentId: commentId))
        guard (200..<300).contains(response.statusCode) else {
            throw CommentError.serverError("서버 오류 (\(response.statusCode))")
        }
    }

    // MARK: - 401 → refresh → 1회 재시도

    private func requestWithRefresh(_ target: CommentAPI) async throws -> Response {
        let firstResult = await provider.requestAsync(target)

        switch firstResult {
        case .success(let response):
            if response.statusCode == 401 {
                do {
                    _ = try await AuthService.shared.refreshAccessToken()
                } catch {
                    TokenStorage.forceLogout()
                    throw CommentError.unauthorized
                }
                let retryResult = await provider.requestAsync(target)
                switch retryResult {
                case .success(let retryResponse):
                    if retryResponse.statusCode == 401 {
                        TokenStorage.forceLogout()
                        throw CommentError.unauthorized
                    }
                    return retryResponse
                case .failure(let err):
                    throw err
                }
            }
            return response

        case .failure(let error):
            throw error
        }
    }

    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let ratio = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
