//
//  TokenStorage.swift
//  JeepChak
//
//  Created by 김은찬 on 12/5/25.
//

import Foundation

enum TokenStorage {
    private static let accessKey  = "accessToken"
    private static let refreshKey = "refreshToken"

    static var accessToken: String? {
        get { UserDefaults.standard.string(forKey: accessKey) }
        set { UserDefaults.standard.setValue(newValue, forKey: accessKey) }
    }

    static var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshKey) }
        set { UserDefaults.standard.setValue(newValue, forKey: refreshKey) }
    }

    static func clear() {
        accessToken = nil
        refreshToken = nil
    }

    /// 토큰 정리 + 로그인 화면으로 강제 이동
    static func forceLogout() {
        clear()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didLogout, object: nil)
        }
    }
}

extension Notification.Name {
    /// 세션 만료 등 강제 로그아웃 (알림창 표시)
    static let didLogout = Notification.Name("didLogout")
    /// 설정에서 직접 로그아웃 (알림 없이 바로 이동)
    static let didManualLogout = Notification.Name("didManualLogout")
}

// JWT payload 디코딩용
private struct JWTPayload: Decodable {
    let exp: TimeInterval
}

private extension String {
    func jwtPayloadData() -> Data? {
        let parts = self.split(separator: ".")
        guard parts.count == 3 else { return nil }

        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        while base64.count % 4 != 0 {
            base64.append("=")
        }

        return Data(base64Encoded: base64)
    }
}

extension TokenStorage {
    /// accessToken 이 유효한지
    static func isAccessTokenValid() -> Bool {
        guard let token = accessToken,
              let data = token.jwtPayloadData(),
              let payload = try? JSONDecoder().decode(JWTPayload.self, from: data) else {
            return false
        }

        let now = Date().timeIntervalSince1970
        return now < payload.exp
    }
}
