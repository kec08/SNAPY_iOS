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
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // 후면 (메인)
                    if let backImage = photo.backImage {
                        Image(uiImage: backImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // 전면 (드래그 가능)
                    if let frontImage = photo.frontImage {
                        DraggablePIP(
                            containerSize: geo.size,
                            pipWidth: 120,
                            pipHeight: 1620,
                            padding: 12
                        ) {
                            Image(uiImage: frontImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                }
            }
            .frame(width: 330, height: 430)

            // 찍은 시간 표시
            Text(photo.capturedAt.albumTimestamp)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.customGray300)
                .padding(.top, 14)
        }
    }
}
