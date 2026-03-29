//
//  AlbumPhotoCard.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/29/26.
//

import SwiftUI

struct AlbumPhotoCard: View {
    let photo: SavedPhoto

    var body: some View {
        VStack(spacing: 8) {
            // 듀얼캠 사진
            ZStack(alignment: .topLeading) {
                // 후면 (메인)
                if let backImage = photo.backImage {
                    Image(uiImage: backImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(width: 330, height: 430)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // 전면 (좌상단 작게)
                if let frontImage = photo.frontImage {
                    Image(uiImage: frontImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.5), radius: 5)
                        .padding(12)
                }
            }

            // 찍은 시간 표시
            Text(photo.capturedAt.albumTimestamp)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.customGray300)
                .padding(.top, 14)
        }
    }
}
