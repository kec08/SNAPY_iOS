//
//  AlbumMissCard.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/2/26.
//

import SwiftUI

struct AlbumMissCard: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("Album_Miss_img")
                .resizable()
                .scaledToFit()
                .frame(height: 160)
                .padding(.bottom, 30)

            Text("오늘 사진을 찍지 못했습니다.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.customGray200)
                .padding(.bottom, 10)

            Text("내일 다시 도전해보세요!")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textWhite)

            Spacer()
        }
        .frame(width: 330, height: 430)
        .padding(.bottom, 34)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.15))
        )
    }
}
