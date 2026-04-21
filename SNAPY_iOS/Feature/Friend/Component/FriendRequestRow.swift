//
//  FriendRequestRow.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI
import Kingfisher

struct FriendRequestRow: View {
    let request: ReceivedFriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void

    @State private var showProfile = false

    var body: some View {
        HStack(spacing: 12) {
            // 프로필 사진
            if let url = request.profileImageUrl, let imgUrl = URL(string: url) {
                KFImage(imgUrl)
                    .resizable()
                    .placeholder { Color.customDarkGray }
                    .fade(duration: 0.2)
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            } else {
                Image("Profile_img")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }

            // 이름 + 핸들
            VStack(alignment: .leading, spacing: 3) {
                Text(request.username)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textWhite)

                Text("@\(request.handle)")
                    .font(.system(size: 13))
                    .foregroundColor(.customGray300)
            }

            Spacer()

            // 수락 (체크) + 거절 (X)
            HStack(spacing: 16) {
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(width: 38, height: 38)
                        .background(Color.customDarkGray, in: Circle())
                }

                Button(action: onReject) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.customGray300)
                        .frame(width: 34, height: 34)
                }
            }
        }
        .padding(.horizontal, 22)
        .contentShape(Rectangle())
        .onTapGesture { showProfile = true }
        .navigationDestination(isPresented: $showProfile) {
            FriendProfileView(
                name: request.username,
                handle: request.handle,
                profileImageUrl: request.profileImageUrl,
                isFriend: false
            )
        }
    }
}
