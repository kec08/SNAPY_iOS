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
    @State private var showDeleteAlert = false
    @State private var showDeleteConfirm = false
    @State private var deleteConfirmText = ""

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

                        // MARK: - 차단 관리
                        sectionHeader("차단 관리")

                        NavigationLink {
                            BlockedUsersView()
                        } label: {
                            HStack {
                                Text("차단된 사용자")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.customGray300)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                        // MARK: - 계정
                        Divider()
                            .background(Color.customGray500)
                            .padding(.top, 24)
                            .padding(.horizontal, 20)

                        // 로그아웃
                        Button {
                            showLogoutAlert = true
                        } label: {
                            Text("로그아웃")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.actionRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                        }

                        // 회원탈퇴
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Text("회원탈퇴")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.customGray300)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                        }
                        .padding(.bottom, 80)
                    }
                }
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
        .alert("회원탈퇴", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("탈퇴하기", role: .destructive) {
                showDeleteConfirm = true
            }
        } message: {
            Text("정말 탈퇴하시겠습니까?")
        }
        .navigationDestination(isPresented: $showDeleteConfirm) {
            DeleteAccountView(viewModel: viewModel)
        }
        .alert("탈퇴 실패", isPresented: Binding(
            get: { viewModel.deleteError != nil },
            set: { if !$0 { viewModel.deleteError = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.deleteError ?? "")
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

// MARK: - 회원탈퇴 확인 화면

struct DeleteAccountView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmText = ""
    @FocusState private var isFocused: Bool

    private var isConfirmed: Bool {
        confirmText == "탈퇴하겠습니다."
    }

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("회원탈퇴")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.textWhite)
                    .padding(.top, 24)

                VStack(alignment: .leading, spacing: 12) {
                    Text("탈퇴 시 아래 내용이 적용됩니다.")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textWhite)

                    VStack(alignment: .leading, spacing: 8) {
                        bulletText("게시물, 스토리, 앨범, 댓글 등 모든 데이터가 삭제됩니다.")
                        bulletText("친구 관계 및 방명록이 모두 해제됩니다.")
                        bulletText("삭제된 데이터는 복구할 수 없습니다.")
                    }

                    Divider()
                        .background(Color.customGray500)
                        .padding(.vertical, 8)

                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.MainYellow)
                        Text("탈퇴 후 3개월 이내에 다시 로그인하면 계정을 복구할 수 있습니다.")
                            .font(.system(size: 13))
                            .foregroundColor(.customGray300)
                    }
                }
                .padding(.top, 28)

                VStack(alignment: .leading, spacing: 8) {
                    Text("탈퇴를 확인하려면 아래에 \"탈퇴하겠습니다.\"를 입력하세요.")
                        .font(.system(size: 14))
                        .foregroundColor(.customGray300)

                    TextField("탈퇴하겠습니다.", text: $confirmText)
                        .font(.system(size: 17))
                        .foregroundColor(.textWhite)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(white: 0.15))
                        .cornerRadius(10)
                        .focused($isFocused)
                }
                .padding(.top, 32)

                Spacer()

                Button {
                    viewModel.deleteAccount()
                } label: {
                    Text("탈퇴하기")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(isConfirmed ? Color.actionRed : Color.customGray500)
                        .foregroundColor(isConfirmed ? .white : .customGray300)
                        .cornerRadius(12)
                }
                .disabled(!isConfirmed)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textWhite)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 80 && abs(value.translation.height) < 100 {
                        dismiss()
                    }
                }
        )
        .onTapGesture {
            isFocused = false
        }
    }

    private func bulletText(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14))
                .foregroundColor(.customGray300)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.customGray300)
                .lineSpacing(4)
        }
    }
}

#Preview {
    SettingsView()
}
