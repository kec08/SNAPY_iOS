//
//  SuggestedFriendRow.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI

struct SuggestedFriendRow: View {
    let friend: SuggestedFriend
    let onAdd: () -> Void
    let onCancel: () -> Void
    let onHide: () -> Void

    @State private var showProfile = false

    var body: some View {
        HStack(spacing: 14) {
            // 프로필 사진
            if let url = friend.profileImageUrl {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Color.customDarkGray
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
            } else {
                Image("Profile_img")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }

            // 이름 + 핸들 + 겹친구
            VStack(alignment: .leading, spacing: 3) {
                Text(friend.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textWhite)

                Text("@\(friend.handle)")
                    .font(.system(size: 13))
                    .foregroundColor(.customGray300)

                if let mutual = friend.mutualText {
                    Text(mutual)
                        .font(.system(size: 12))
                        .foregroundColor(.customGray300)
                }
            }

            Spacer()

            // 우측 버튼
            switch friend.requestState {
            case .none:
                HStack(spacing: 12) {
                    Button(action: onAdd) {
                        Text("추가")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.mainYellow)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Color.customDarkGray, in: RoundedRectangle(cornerRadius: 30))
                    }

                    Button(action: onHide) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.customGray300)
                            .frame(width: 32, height: 32)
                    }
                }

            case .requested:
                Button(action: onCancel) {
                    Text("취소")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.customGray300)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.customDarkGray, in: RoundedRectangle(cornerRadius: 30))
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { showProfile = true }
        .navigationDestination(isPresented: $showProfile) {
            FriendProfileView(
                name: friend.name,
                handle: friend.handle,
                profileImageUrl: friend.profileImageUrl
            )
        }
    }
}
