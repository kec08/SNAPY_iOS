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
    let emptyState: EmptySlotState
    var onTapSnap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(slot.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(slot.timeRange)
                .font(.system(size: 13))
                .foregroundColor(.customGray300)
                .padding(.bottom, 8)

            if let photo = photo {
                // 사진 있음
                AlbumPhotoCard(photo: photo)
            } else if emptyState == .canTake {
                // 지금 찍을 수 있음
                AlbumEmptyCard(onTapSnap: onTapSnap)
            } else {
                // 이미 지나감
                AlbumMissCard()
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}
