//
//  HomeHeader.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI

struct HomeHeader: View {
    var body: some View {
        ZStack {
            Image("SNAPY_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 25)
            
            HStack {
                Spacer()
                Button {
                    // 알림 화면
                } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
