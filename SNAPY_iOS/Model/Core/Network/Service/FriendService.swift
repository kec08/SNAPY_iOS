//
//  FriendService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/14/26.
//

import Foundation
import Moya

final class FriendService {
    static let shared = FriendService()
    private let provider = MoyaProvider<FriendAPI>()

    private init() {}

    // MARK: - 추천 친구 조회

    func getRecommendedFriends() async throws -> [RecommendedFriendData] {
        let response = try await requestWithRefresh(.getRecommendedFriends)
        guard (200..<300).contains(response.statusCode) else {
            throw FriendError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(RecommendedFriendsResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw FriendError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 친구 목록

    func getFriends(handle: String) async throws -> [FriendData] {
        let response = try await requestWithRefresh(.getFriends(handle: handle))
        guard (200..<300).contains(response.statusCode) else {
            throw FriendError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(FriendListResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw FriendError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 연락처 동기화

    func syncContacts(phones: [String]) async throws -> [ContactUserData] {
        print("[FriendService] 연락처 동기화 - \(phones.count)개 번호")
        let response = try await requestWithRefresh(.syncContacts(phones: phones))
        print("[FriendService] 응답 코드 \(response.statusCode)")
        guard (200..<300).contains(response.statusCode) else {
            throw FriendError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(ContactSyncResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw FriendError.serverError(decoded.message)
        }
        return data.contacts
    }

    // MARK: - 유저 검색

    func searchUsers(query: String) async throws -> [RecommendedFriendData] {
        let response = try await requestWithRefresh(.searchUsers(query: query))
        guard (200..<300).contains(response.statusCode) else {
            throw FriendError.serverError(extractMessage(from: response))
        }
        // 응답: [{ handle, username, profileImageUrl }] — RecommendedFriendData 와 동일 형식
        let decoded = try JSONDecoder().decode(BaseResponse<[RecommendedFriendData]>.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw FriendError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 친구 요청 보내기

    func sendRequest(handle: String) async throws {
        print("[FriendService] 친구 요청 보내기 - \(handle)")
        let response = try await requestWithRefresh(.sendRequest(handle: handle))
        print("[FriendService] 응답 코드 \(response.statusCode)")
        guard (200..<300).contains(response.statusCode) else {
            throw FriendError.serverError(extractMessage(from: response))
        }
    }

    // MARK: - 친구 요청 취소

    func cancelRequest(handle: String) async throws {
        print("[FriendService] 친구 요청 취소 - \(handle)")
        let response = try await requestWithRefresh(.cancelRequest(handle: handle))
        print("[FriendService] 응답 코드 \(response.statusCode)")
        guard (200..<300).contains(response.statusCode) else {
            throw FriendError.serverError(extractMessage(from: response))
        }
    }

    // MARK: - 받은 요청 목록

    func getReceivedRequests() async throws -> [ReceivedFriendRequest] {
        let response = try await requestWithRefresh(.getReceivedRequests)
        guard (200..<300).contains(response.statusCode) else {
            throw FriendError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(ReceivedRequestsResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw FriendError.serverError(decoded.message)
        }
        return data
    }

    // MARK: - 요청 처리 (수락/거절)

    func processRequest(requestId: Int, action: FriendRequestAction) async throws {
        print("[FriendService] 요청 처리 - id=\(requestId), action=\(action.rawValue)")
        let response = try await requestWithRefresh(.processRequest(requestId: requestId, action: action))
        print("[FriendService] 응답 코드 \(response.statusCode)")
        guard (200..<300).contains(response.statusCode) else {
            throw FriendError.serverError(extractMessage(from: response))
        }
    }

    // MARK: - 요청 상태 조회

    func getRequestStatus(handle: String) async throws -> FriendRequestStatus {
        let response = try await requestWithRefresh(.getRequestStatus(handle: handle))
        guard (200..<300).contains(response.statusCode) else {
            throw FriendError.serverError(extractMessage(from: response))
        }
        let decoded = try JSONDecoder().decode(FriendRequestStatusResponse.self, from: response.data)
        guard decoded.success, let data = decoded.data else {
            throw FriendError.serverError(decoded.message)
        }
        return data.requestStatus ?? .none
    }

    // MARK: - 친구 삭제

    func removeFriend(handle: String) async throws {
        print("[FriendService] 친구 삭제 - \(handle)")
        let response = try await requestWithRefresh(.removeFriend(handle: handle))
        print("[FriendService] 응답 코드 \(response.statusCode)")
        guard (200..<300).contains(response.statusCode) else {
            throw FriendError.serverError(extractMessage(from: response))
        }
    }

    // MARK: - 401 재시도

    private func requestWithRefresh(_ target: FriendAPI) async throws -> Response {
        let firstResult = await provider.requestAsync(target)
        switch firstResult {
        case .success(let response):
            if response.statusCode == 401 {
                do {
                    _ = try await AuthService.shared.refreshAccessToken()
                } catch {
                    TokenStorage.clear()
                    throw FriendError.unauthorized
                }
                let retryResult = await provider.requestAsync(target)
                switch retryResult {
                case .success(let r):
                    if r.statusCode == 401 { throw FriendError.unauthorized }
                    return r
                case .failure(let e): throw e
                }
            }
            return response
        case .failure(let error):
            throw error
        }
    }

    // MARK: - 에러 메시지 추출

    private func extractMessage(from response: Response) -> String {
        struct SpringError: Decodable { let message: String? }
        if let err = try? JSONDecoder().decode(SpringError.self, from: response.data) {
            return err.message ?? "서버 오류 (\(response.statusCode))"
        }
        return "서버 오류 (\(response.statusCode))"
    }
}

enum FriendError: Error, LocalizedError {
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "로그인이 필요합니다."
        case .serverError(let msg): return msg
        }
    }
}
