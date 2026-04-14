//
//  FriendRequestView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI

struct FriendRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FriendViewModel()

    @State private var requests: [ReceivedFriendRequest] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: 요청 섹션
                    if requests.isEmpty {
                        // 요청 없음
                        VStack(spacing: 8) {
                            Text("들어온 친구 요청이 없습니다")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.customGray300)

                            Text("추천 친구에게 요청을 보내보세요!")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.mainYellow)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                        .padding(.bottom, 30)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        // 요청 있음
                        ForEach(requests) { request in
                            FriendRequestRow(
                                request: request,
                                onAccept: { withAnimation(.easeInOut(duration: 0.3)) { acceptRequest(request) } },
                                onReject: { withAnimation(.easeInOut(duration: 0.3)) { rejectRequest(request) } }
                            )
                            .transition(.opacity.combined(with: .offset(x: -50)))
                        }
                        .padding(.top, 16)
                    }

                    // MARK: 추천 친구 섹션 (요청이 없을 때만)
                    if requests.isEmpty {
                        Text("추천 친구")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textWhite)
                            .padding(.horizontal, 22)
                            .padding(.top, 24)
                            .padding(.bottom, 12)

                        ForEach(viewModel.filteredFriends) { friend in
                            SuggestedFriendRow(
                                friend: friend,
                                onAdd: { viewModel.sendRequest(to: friend) },
                                onCancel: { viewModel.cancelRequest(to: friend) },
                                onHide: { viewModel.hideFriend(friend) }
                            )
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textWhite)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("친구 요청")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textWhite)
            }
        }
        .toolbarBackground(Color.backgroundBlack, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadRequests()
        }
    }

    private func loadRequests() async {
        isLoading = true
        do {
            requests = try await FriendService.shared.getReceivedRequests()
        } catch {
            print("[FriendRequestView] 받은 요청 로드 실패: \(error)")
        }
        isLoading = false
    }

    private func acceptRequest(_ request: ReceivedFriendRequest) {
        Task {
            do {
                try await FriendService.shared.processRequest(requestId: request.requestId, action: .approve)
                withAnimation(.easeInOut(duration: 0.3)) {
                    requests.removeAll { $0.id == request.id }
                }
            } catch {
                print("[FriendRequestView] 수락 실패: \(error)")
            }
        }
    }

    private func rejectRequest(_ request: ReceivedFriendRequest) {
        Task {
            do {
                try await FriendService.shared.processRequest(requestId: request.requestId, action: .reject)
                withAnimation(.easeInOut(duration: 0.3)) {
                    requests.removeAll { $0.id == request.id }
                }
            } catch {
                print("[FriendRequestView] 거절 실패: \(error)")
            }
        }
    }
}
