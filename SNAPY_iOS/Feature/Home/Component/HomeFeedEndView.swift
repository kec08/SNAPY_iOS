//
//  HomeFeedEndView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI

struct HomeFeedEndView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image("Wink_img")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(.bottom, 12)

            Text("친구의 게시물을 모두 확인했습니다")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Text("내일은 또 어떤 순간이 있을까요?")
                .font(.system(size: 13))
                .foregroundColor(.customGray300)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    HomeFeedEndView()
        .background(Color.backgroundBlack)
}
