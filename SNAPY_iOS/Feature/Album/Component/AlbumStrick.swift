//
//  AlbumStrickView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/25/26.
//

import SwiftUI

struct AlbumStrick: View {
    
    var streakCount: Int
    var maxStreak: Int = 5
    
    private var progress: CGFloat {
        guard maxStreak > 0 else { return 0 }
        return min(CGFloat(streakCount) / CGFloat(maxStreak), 1.0)
    }
    
    private var level: Int {
        min(streakCount, maxStreak)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { geo in
                Capsule()
                    .fill(Color.textWhite)
                    .frame(height: 10)
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFE73E"),
                                Color(hex: "FF1B23")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 10)
                    .opacity(progress == 0 ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
            .padding(.top , 18)
            
            Image("Strick_\(level)")
                .resizable()
                .frame(width: 40, height: 40)
                .offset(y: -10)
                .offset(x: -10)
        }
        .frame(height: 36)
        .padding(.horizontal, 56)
    }
}

struct AlbumStrick_Previews: PreviewProvider {
    static var previews: some View {
        AlbumStrick(streakCount: 3)
    }
}
