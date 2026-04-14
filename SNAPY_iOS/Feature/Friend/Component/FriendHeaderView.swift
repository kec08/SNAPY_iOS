//
//  FriendHeaderView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/13/26.
//

import SwiftUI

struct FriendHeaderView: View {
    let onTapFriendRequest: () -> Void

    var body: some View {
        ZStack {
            Text("친구")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.textWhite)

            HStack {
                Spacer()
                Button(action: onTapFriendRequest) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.textWhite)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}
