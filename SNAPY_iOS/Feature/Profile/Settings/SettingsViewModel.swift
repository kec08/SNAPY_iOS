//
//  SettingsViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/20/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var feedVisibility: Visibility = .friendsOnly
    @Published var pastAlbumVisibility: Visibility = .friendsOnly
    @Published var isLoading: Bool = false

    // MARK: - 설정 로드

    func loadSettings() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let settings = try await ProfileService.shared.fetchSettings()
            feedVisibility = settings.feedVisibilityEnum
            pastAlbumVisibility = settings.pastAlbumVisibilityEnum
        } catch {
            print("[Settings] 설정 로드 실패: \(error)")
        }
    }

    // MARK: - 피드 & 스토리 공개 범위 변경

    func setFeedVisibility(_ visibility: Visibility) {
        guard feedVisibility != visibility else { return }
        let previous = feedVisibility
        feedVisibility = visibility

        Task {
            do {
                try await ProfileService.shared.updateFeedVisibility(visibility)
            } catch {
                print("[Settings] 피드 공개 범위 변경 실패: \(error)")
                feedVisibility = previous
            }
        }
    }

    // MARK: - 과거 앨범 공개 범위 변경

    func setPastAlbumVisibility(_ visibility: Visibility) {
        guard pastAlbumVisibility != visibility else { return }
        let previous = pastAlbumVisibility
        pastAlbumVisibility = visibility

        Task {
            do {
                try await ProfileService.shared.updatePastAlbumVisibility(visibility)
            } catch {
                print("[Settings] 과거 앨범 공개 범위 변경 실패: \(error)")
                pastAlbumVisibility = previous
            }
        }
    }

    // MARK: - 로그아웃

    func logout() {
        Task {
            do {
                try await AuthService.shared.logout()
            } catch {
                print("[Settings] 로그아웃 실패: \(error)")
            }
            TokenStorage.clear()
            NotificationCenter.default.post(name: .didManualLogout, object: nil)
        }
    }
}
