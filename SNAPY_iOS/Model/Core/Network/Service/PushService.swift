//
//  PushService.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/12/26.
//

import Foundation
import Moya

final class PushService {
    static let shared = PushService()
    private let provider = MoyaProvider<PushAPI>()

    private init() {}

    /// 디바이스 토큰 서버에 등록
    func registerToken(_ token: String) async {
        #if DEBUG
        let environment = "SANDBOX"
        #else
        let environment = "PRODUCTION"
        #endif

        let result = await provider.requestAsync(.registerToken(token: token, environment: environment))
        switch result {
        case .success(let response):
            print("[PushService] 토큰 등록 응답 \(response.statusCode)")
        case .failure(let error):
            print("[PushService] 토큰 등록 실패: \(error)")
        }
    }

    /// 디바이스 토큰 서버에서 삭제 (로그아웃 시)
    func deleteToken(_ token: String) async {
        let result = await provider.requestAsync(.deleteToken(token: token))
        switch result {
        case .success(let response):
            print("[PushService] 토큰 삭제 응답 \(response.statusCode)")
        case .failure(let error):
            print("[PushService] 토큰 삭제 실패: \(error)")
        }
    }
}
