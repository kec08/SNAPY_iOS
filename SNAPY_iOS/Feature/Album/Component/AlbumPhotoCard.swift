//
//  AlbumPhotoCard.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/29/26.
//

import SwiftUI

struct AlbumPhotoCard: View {
    let photo: PhotoData

    var body: some View {
        VStack(spacing: 8) {
            // 듀얼캠 사진
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // 후면 (메인) - 서버 URL
                    AsyncImage(url: URL(string: photo.backImageUrl ?? "")) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(white: 0.15))
                                .overlay(ProgressView().tint(.white))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        case .failure:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(white: 0.15))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            Color.clear
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)

                    // 전면 (드래그 가능 PIP) - 서버 URL
                    DraggablePIP(
                        containerSize: geo.size,
                        pipWidth: 120,
                        pipHeight: 160,
                        padding: 12
                    ) {
                        AsyncImage(url: URL(string: photo.frontImageUrl ?? "")) { phase in
                            switch phase {
                            case .empty:
                                Color(white: 0.2).overlay(ProgressView().tint(.white))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Color(white: 0.2).overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                            @unknown default:
                                Color.clear
                            }
                        }
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
