//
//  AlbumPhotoCard.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/29/26.
//

import SwiftUI
import Kingfisher

struct AlbumPhotoCard: View {
    let photo: PhotoData

    var body: some View {
        VStack(spacing: 8) {
            // 듀얼캠 사진
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // 후면 (메인) - 서버 URL
                    KFImage(URL(string: photo.backImageUrl ?? ""))
                        .resizable()
                        .placeholder {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(white: 0.15))
                                .overlay(ProgressView().tint(.white))
                        }
                        .fade(duration: 0.2)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    // 전면 (드래그 가능 PIP) - 서버 URL
                    DraggablePIP(
                        containerSize: geo.size,
                        pipWidth: 120,
                        pipHeight: 160,
                        padding: 12
                    ) {
                        KFImage(URL(string: photo.frontImageUrl ?? ""))
                            .resizable()
                            .placeholder { Color(white: 0.2).overlay(ProgressView().tint(.white)) }
                            .fade(duration: 0.2)
                            .aspectRatio(contentMode: .fill)
                    }
                }
            }
            .frame(width: 330, height: 430)

            Text(photo.capturedTimeText ?? (photo.albumSlot?.name ?? photo.type))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.customGray300)
                .padding(.top, 14)
        }
    }
}
