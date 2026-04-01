//
//  AlbumTimeSlotCard.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/29/26.
//

import SwiftUI

struct AlbumTimeSlotCard: View {
    let slot: AlbumSlot
    let photo: SavedPhoto?

    var body: some View {
        VStack(spacing: 8) {
            // 슬롯 이름 + 시간 범위
            Text(slot.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(slot.timeRange)
                .font(.system(size: 13))
                .foregroundColor(.customGray300)
                .padding(.bottom, 8)

            if let photo = photo {
                AlbumPhotoCard(photo: photo)
            } else {
                AlbumEmptyCard()
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}
