//
//  AlbumEmptyCard.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/29/26.
//

import SwiftUI

struct AlbumEmptyCard: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("Not_filming_img")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 148)
                .padding(.bottom, 40)

            Text("아직 오늘의 사진을 찍지 않으셨습니다.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.customGray200)

            Text("클릭하여 스냅찍기 >")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.textWhite)

            Spacer()
        }
        .frame(width: 300, height: 430)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.15))
        )
    }
}
