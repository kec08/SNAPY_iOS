//
//  AlbumHeader.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/25/26.
//

import SwiftUI

struct AlbumHeader: View {
    let dateString: String
    var goToPreviousDay: () -> Void
    var goToNextDay: () -> Void

    var body: some View {
        ZStack {
            Text(dateString)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            HStack {
                Button {
                    goToPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.textWhite)
                }
                .buttonStyle(.glass)

                Spacer()

                Button {
                    goToNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.textWhite)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}
