//
//  FriendHeaderView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI

struct FriendHeaderView: View {
    let pendingCount: Int
    let onTapFriendRequest: () -> Void

    init(pendingCount: Int = 0, onTapFriendRequest: @escaping () -> Void) {
        self.pendingCount = pendingCount
        self.onTapFriendRequest = onTapFriendRequest
    }

    var body: some View {
        ZStack {
            Text("친구")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textWhite)

            HStack {
                Spacer()
                Button(action: onTapFriendRequest) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.textWhite)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())

                        if pendingCount > 0 {
                            Text(pendingCount > 99 ? "99+" : "\(pendingCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -2)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}
