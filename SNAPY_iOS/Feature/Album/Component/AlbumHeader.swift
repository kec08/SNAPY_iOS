//
//  AlbumHeader.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/25/26.
//

import SwiftUI

struct AlbumHeader: View {
    var goToPreviousDay: () -> Void
    var goToNextDay: () -> Void
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("2025.03.10 (화)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
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
        .padding(.bottom, 40)
    }
}
