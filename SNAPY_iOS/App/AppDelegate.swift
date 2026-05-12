//
//  AppDelegate.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/12/26.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        requestPushPermission(application)
        return true
    }

    // MARK: - 푸시 권한 요청

    private func requestPushPermission(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("[Push] 알림 권한: \(granted), error: \(String(describing: error))")
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }

    // MARK: - 디바이스 토큰 수신

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[Push] 디바이스 토큰: \(token)")

        // UserDefaults에 저장
        UserDefaults.standard.set(token, forKey: "deviceToken")

        // 로그인 상태면 서버에 등록
        if TokenStorage.accessToken != nil {
            Task {
                await PushService.shared.registerToken(token)
            }
        }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[Push] 토큰 등록 실패: \(error)")
    }

    // MARK: - 포그라운드 알림 수신

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 앱이 포그라운드일 때도 배너 + 사운드 표시
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - 알림 탭 처리

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("[Push] 알림 탭: \(userInfo)")
        // 추후 딥링크 처리
        completionHandler()
    }
}
