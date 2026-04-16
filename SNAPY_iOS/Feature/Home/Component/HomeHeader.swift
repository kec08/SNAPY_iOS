//
//  HomeHeader.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI

struct HomeHeader: View {
    var body: some View {
        HStack {
            Spacer()

            Image("Login_TextLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 25)

            Spacer()

            Button {
                // 알림 화면 (임시)
            } label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
