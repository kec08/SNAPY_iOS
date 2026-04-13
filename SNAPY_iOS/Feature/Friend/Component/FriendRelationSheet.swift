//
//  FriendRelationSheet.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/14/26.
//

import SwiftUI

struct FriendRelationSheet: View {
    let name: String
    let handle: String
    let onRemoveFriend: () -> Void

    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 8)

            Text(name)
                .font(.system(size: 20, weight: .bold))

            Text("@\(handle)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer().frame(height: 4)

            // 관계
            VStack(spacing: 10) {
                Text("관계")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.mainYellow)
                    Text("친구")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.mainYellow)
                }
            }

            Spacer()

            Button {
                showAlert = true
            } label: {
                Text("친구 삭제")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .alert("친구를 삭제하시겠습니까?", isPresented: $showAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                onRemoveFriend()
            }
        } message: {
            Text("\(name)님을 친구 목록에서 삭제합니다.")
        }
    }
}
