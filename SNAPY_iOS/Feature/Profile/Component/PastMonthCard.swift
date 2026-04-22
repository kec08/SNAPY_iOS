//
//  PastMonthCard.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/22/26.
//

import SwiftUI
import Kingfisher

/// 그리드 1칸 사이즈의 이전 달 요약 카드
struct PastMonthCard: View {
    let summary: PastMonthSummary

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 대표 사진 배경
            if let url = summary.thumbnailUrl, let imgUrl = URL(string: url) {
                KFImage(imgUrl)
                    .resizable()
                    .placeholder { Color(white: 0.12) }
                    .fade(duration: 0.2)
                    .scaledToFill()
            } else {
                Color(white: 0.12)
            }

            // 어두운 오버레이
            Color.black.opacity(0.4)

            // 월 + 다시보기
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.displayText)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 2) {
                    Text("클릭하여 다시보기")
                        .font(.system(size: 9, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 7, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.8))
            }
            .padding(.leading, 8)
            .padding(.bottom, 8)
        }
        .aspectRatio(3.0/4.0, contentMode: .fit)
        .clipped()
    }
}
