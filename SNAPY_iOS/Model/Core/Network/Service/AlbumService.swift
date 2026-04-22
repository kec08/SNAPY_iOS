//
//  AlbumService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/9/26.
//

import Foundation
import UIKit
import Moya

// MARK: - Moya async helper (file-local)

enum AlbumError: Error, LocalizedError {
    case unauthorized
    case serverError(String)
    case invalidImage
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .unauthorized:           return "로그인이 필요합니다."
        case .serverError(let msg):   return msg
        case .invalidImage:           return "이미지 데이터가 유효하지 않습니다."
        case .decodingFailed:         return "응답을 해석할 수 없습니다."
        }
    }
}

// Spring Boot 기본 에러 응답 형식
private struct SpringErrorResponse: Decodable {
    let status: Int?
    let error: String?
    let message: String?
    let timestamp: String?
}

private func extractErrorMessage(from data: Data, statusCode: Int) -> String {
    // 1차: BaseResponse 형식 시도
    if let baseError = try? JSONDecoder().decode(BaseResponse<EmptyData>.self, from: data),
       !baseError.message.isEmpty {
        return baseError.message
    }
    // 2차: Spring Boot 에러 형식 시도
    if let springError = try? JSONDecoder().decode(SpringErrorResponse.self, from: data),
       let msg = springError.message {
        return msg
    }
    // 3차: 그냥 raw body
    if let raw = String(data: data, encoding: .utf8), !raw.isEmpty {
        return "[\(statusCode)] \(raw)"
    }
    return "서버 오류 (\(statusCode))"
}

final class AlbumService {
    static let shared = AlbumService()
    private let provider = MoyaProvider<AlbumAPI>()

    private init() {}

    // MARK: - 업로드

    func upload(front: UIImage, back: UIImage, type: AlbumType) async throws -> AlbumUploadData {
        print("[AlbumService] 이미지 전송 - type=\(type.rawValue)")

        let response = try await requestWithRefresh(.upload(front: front, back: back, type: type))
        print("[AlbumService] 응답 코드 \(response.statusCode)")
        if let body = String(data: response.data, encoding: .utf8) {
            print("[AlbumService] 응답 본문 \(body)")
        }

        guard (200..<300).contains(response.statusCode) else {
            let msg = extractErrorMessage(from: response.data, statusCode: response.statusCode)
            throw AlbumError.serverError(msg)
        }

        do {
            let decoded = try JSONDecoder().decode(AlbumUploadResponse.self, from: response.data)
            guard decoded.success, let data = decoded.data else {
                throw AlbumError.serverError(decoded.message)
            }
            return data
        } catch let err as AlbumError {
            throw err
        } catch {
            throw AlbumError.decodingFailed
        }
    }

    // MARK: - 오늘 앨범 조회

    func fetchToday() async throws -> DailyAlbumData {
        let response = try await requestWithRefresh(.fetchToday)
        print("[AlbumService] fetchToday 응답 코드 \(response.statusCode)")
        if let body = String(data: response.data, encoding: .utf8) {
            print("[AlbumService] fetchToday 응답 본문 \(body)")
        }
        guard (200..<300).contains(response.statusCode) else {
            let msg = extractErrorMessage(from: response.data, statusCode: response.statusCode)
            throw AlbumError.serverError(msg)
        }
        do {
            let decoded = try JSONDecoder().decode(TodayAlbumResponse.self, from: response.data)
            guard decoded.success, let data = decoded.data else {
                throw AlbumError.serverError(decoded.message)
            }
            return data
        } catch let err as AlbumError {
            throw err
        } catch {
            print("[AlbumService] fetchToday 디코딩 실패: \(error)")
            throw AlbumError.decodingFailed
        }
    }

    // MARK: - 특정 앨범 상세 (DailyAlbumData 형식, /today 와 동일)

    /// /api/albums/{albumId} 를 DailyAlbumData(photos 포함) 형식으로 파싱 시도.
    /// 백엔드가 photos 배열을 포함해서 응답하면 과거 날짜 사진도 볼 수 있다.
    func fetchAlbumAsDaily(albumId: Int) async throws -> DailyAlbumData {
        let response = try await requestWithRefresh(.fetchDetail(albumId: albumId))
        print("[AlbumService] 앨범 상세 응답 코드 \(response.statusCode)")
        if let body = String(data: response.data, encoding: .utf8) {
            print("[AlbumService] 앨범 상세 응답 본문 \(body)")
        }
        guard (200..<300).contains(response.statusCode) else {
            let msg = extractErrorMessage(from: response.data, statusCode: response.statusCode)
            throw AlbumError.serverError(msg)
        }
        do {
            // /today 와 같은 형식 (DailyAlbumData) 으로 파싱 시도
            let decoded = try JSONDecoder().decode(TodayAlbumResponse.self, from: response.data)
            guard decoded.success, let data = decoded.data else {
                throw AlbumError.serverError(decoded.message)
            }
            return data
        } catch let err as AlbumError {
            throw err
        } catch {
            print("[AlbumService] DailyAlbumData 파싱 실패: \(error)")
            throw AlbumError.decodingFailed
        }
    }

    // MARK: - 월간 앨범 목록

    /// GET /api/albums — 전체 앨범 목록 조회 (파라미터 없음)
    func fetchAll() async throws -> [AlbumListItemData] {
        let response = try await requestWithRefresh(.fetchAll)
        guard (200..<300).contains(response.statusCode) else {
            let msg = extractErrorMessage(from: response.data, statusCode: response.statusCode)
            throw AlbumError.serverError(msg)
        }
        do {
            let decoded = try JSONDecoder().decode(AlbumListResponse.self, from: response.data)
            guard decoded.success, let data = decoded.data else {
                throw AlbumError.serverError(decoded.message)
            }
            return data
        } catch let err as AlbumError {
            throw err
        } catch {
            throw AlbumError.decodingFailed
        }
    }

    func fetchAlbums(month: Int) async throws -> [AlbumListItemData] {
        let response = try await requestWithRefresh(.fetchByMonth(month: month))
        guard (200..<300).contains(response.statusCode) else {
            let msg = extractErrorMessage(from: response.data, statusCode: response.statusCode)
            throw AlbumError.serverError(msg)
        }
        do {
            let decoded = try JSONDecoder().decode(AlbumListResponse.self, from: response.data)
            guard decoded.success, let data = decoded.data else {
                throw AlbumError.serverError(decoded.message)
            }
            return data
        } catch let err as AlbumError {
            throw err
        } catch {
            throw AlbumError.decodingFailed
        }
    }

    // MARK: - 게시 (publish)

    /// /api/albums/{albumId}/publish — 앨범을 피드에 공개한다.
    func publish(albumId: Int) async throws -> AlbumPublishData {
        let response = try await requestWithRefresh(.publish(albumId: albumId))
        print("[AlbumService] publish 응답 코드 \(response.statusCode)")
        if let body = String(data: response.data, encoding: .utf8) {
            print("[AlbumService] publish 응답 본문 \(body)")
        }
        guard (200..<300).contains(response.statusCode) else {
            let msg = extractErrorMessage(from: response.data, statusCode: response.statusCode)
            throw AlbumError.serverError(msg)
        }
        do {
            let decoded = try JSONDecoder().decode(AlbumPublishResponse.self, from: response.data)
            guard decoded.success, let data = decoded.data else {
                throw AlbumError.serverError(decoded.message)
            }
            return data
        } catch let err as AlbumError {
            throw err
        } catch {
            throw AlbumError.decodingFailed
        }
    }

    // MARK: - 캘린더 전체 조회

    /// /api/albums/calendar — 사용자의 모든 앨범을 한 번에 가져온다.
    func fetchCalendar() async throws -> [AlbumListItemData] {
        let response = try await requestWithRefresh(.fetchCalendar)
        guard (200..<300).contains(response.statusCode) else {
            let msg = extractErrorMessage(from: response.data, statusCode: response.statusCode)
            throw AlbumError.serverError(msg)
        }
        do {
            let decoded = try JSONDecoder().decode(AlbumListResponse.self, from: response.data)
            guard decoded.success, let data = decoded.data else {
                throw AlbumError.serverError(decoded.message)
            }
            return data
        } catch let err as AlbumError {
            throw err
        } catch {
            throw AlbumError.decodingFailed
        }
    }

    // MARK: - 앨범 상세

    func fetchAlbumDetail(albumId: Int) async throws -> [AlbumListItemData] {
        let response = try await requestWithRefresh(.fetchDetail(albumId: albumId))
        guard (200..<300).contains(response.statusCode) else {
            let msg = extractErrorMessage(from: response.data, statusCode: response.statusCode)
            throw AlbumError.serverError(msg)
        }
        do {
            let decoded = try JSONDecoder().decode(AlbumDetailResponse.self, from: response.data)
            guard decoded.success, let data = decoded.data else {
                throw AlbumError.serverError(decoded.message)
            }
            return data
        } catch let err as AlbumError {
            throw err
        } catch {
            throw AlbumError.decodingFailed
        }
    }

    // MARK: - 401 → refresh → 1회 재시도

    /// 1차 호출 → 401 이면 AccessToken 재발급 후 동일 요청 1회 재시도.
    /// 무한 루프 방지를 위해 재시도는 1회만 수행한다.
    private func requestWithRefresh(_ target: AlbumAPI) async throws -> Response {
        let firstResult = await provider.requestAsync(target)

        switch firstResult {
        case .success(let response):
            if response.statusCode == 401 {
                do {
                    _ = try await AuthService.shared.refreshAccessToken()
                } catch {
                    TokenStorage.clear()
                    throw AlbumError.unauthorized
                }
                let retryResult = await provider.requestAsync(target)
                switch retryResult {
                case .success(let retryResponse):
                    if retryResponse.statusCode == 401 {
                        TokenStorage.clear()
                        throw AlbumError.unauthorized
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
}

