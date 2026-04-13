//
//  FriendRequestView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI

// 친구 요청 모델
struct FriendRequest: Identifiable {
    let id = UUID()
    let name: String
    let handle: String
    let profileImageUrl: String?
}

struct FriendRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FriendViewModel()

    // 임시 목 데이터
    @State private var requests: [FriendRequest] = [
        FriendRequest(name: "김은찬", handle: "silver_c.ld", profileImageUrl: nil),
        FriendRequest(name: "김은찬", handle: "silver_c.ld", profileImageUrl: nil),
        FriendRequest(name: "김은찬", handle: "silver_c.ld", profileImageUrl: nil),
    ]

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
                    } else {
                        // 요청 있음
                        ForEach(requests) { request in
                            FriendRequestRow(
                                request: request,
                                onAccept: { acceptRequest(request) },
                                onReject: { rejectRequest(request) }
                            )
                        }
                        .padding(.top, 16)
                    }

                    // MARK: 추천 친구 섹션
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
    }

    private func acceptRequest(_ request: FriendRequest) {
        requests.removeAll { $0.id == request.id }
    }

    private func rejectRequest(_ request: FriendRequest) {
        requests.removeAll { $0.id == request.id }
    }
}
