//
//  HomeHeader.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI

struct HomeHeader: View {
    var body: some View {
        ZStack {
            // 로고 (가운데 정렬)
            Image("SNAPY_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 25)

            // 알림 버튼 (오른쪽 고정)
            HStack {
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
