//
//  HomeHeader.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI

struct HomeHeader: View {
    @Binding var showNotification: Bool
    var unreadCount: Int64 = 0

    var body: some View {
        HStack {
            // 왼쪽 여백용 (알림 버튼과 대칭)
            Color.clear
                .frame(width: 52, height: 44)

            Spacer()

            Image("SNAPY_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 25)

            Spacer()

            Button {
                showNotification = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())

                    if unreadCount > 0 {
                        Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
