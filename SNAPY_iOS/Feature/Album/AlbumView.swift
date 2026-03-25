//
//  AlbumView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct AlbumView: View {
    var body: some View {
        VStack {
            AlbumHeader(
                goToPreviousDay: {}, goToNextDay: {}
            )
            
            AlbumStrick(streakCount: 5)
            
            Spacer()
            Text("Album")
            Spacer()
        }
    }
}

struct AlbumView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumView()
    }
}
