//
//  FriendRequestRow.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI

struct FriendRequestRow: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void

    @State private var showProfile = false

    var body: some View {
        HStack(spacing: 12) {
            // 프로필 사진
            if let url = request.profileImageUrl {
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

            // 이름 + 핸들
            VStack(alignment: .leading, spacing: 3) {
                Text(request.name)
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
                name: request.name,
                handle: request.handle,
                profileImageUrl: request.profileImageUrl
            )
        }
    }
}
