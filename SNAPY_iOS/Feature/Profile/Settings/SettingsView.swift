//
//  SettingsView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/20/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // 헤더
                ZStack {
                    Text("설정")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.textWhite)

                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.textWhite)
                        }
                        .buttonStyle(.glass)
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // MARK: - 피드 & 스토리
                        sectionHeader("피드 & 스토리")

                        settingToggleRow(
                            title: "공개",
                            isOn: viewModel.feedVisibility == .publicAll
                        ) {
                            viewModel.setFeedVisibility(.publicAll)
                        }

                        settingToggleRow(
                            title: "친구만",
                            isOn: viewModel.feedVisibility == .friendsOnly
                        ) {
                            viewModel.setFeedVisibility(.friendsOnly)
                        }

                        // MARK: - 과거 앨범
                        sectionHeader("과거 앨범")
                            .padding(.top, 16)

                        settingToggleRow(
                            title: "공개",
                            isOn: viewModel.pastAlbumVisibility == .publicAll
                        ) {
                            viewModel.setPastAlbumVisibility(.publicAll)
                        }

                        settingToggleRow(
                            title: "친구만",
                            isOn: viewModel.pastAlbumVisibility == .friendsOnly
                        ) {
                            viewModel.setPastAlbumVisibility(.friendsOnly)
                        }

                        // 안내 문구
                        Text("계정을 친구 공개로 설정하면, 승인된 친구들만 회원님의 피드, 스토리, 과거 앨범을 볼 수 있습니다. 설정 변경 전 업로드된 모든 콘텐츠에도 동일하게 적용됩니다.")
                            .font(.system(size: 13))
                            .foregroundColor(.customGray200)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .lineSpacing(4)

                        Divider()
                            .background(Color.customGray500)
                            .padding(.top, 24)
                            .padding(.horizontal, 20)
                    }
                }

                Spacer()

                // 로그아웃
                Button {
                    showLogoutAlert = true
                } label: {
                    Text("로그아웃")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.actionRed)
                }
                .padding(.bottom, 60)
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadSettings()
        }
        .alert("로그아웃", isPresented: $showLogoutAlert) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive) {
                viewModel.logout()
            }
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
    }

    // MARK: - 섹션 헤더

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.customGray200)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    // MARK: - 토글 행

    @ViewBuilder
    private func settingToggleRow(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: Binding(
                get: { isOn },
                set: { _ in action() }
            ))
            .labelsHidden()
            .tint(.green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
}
