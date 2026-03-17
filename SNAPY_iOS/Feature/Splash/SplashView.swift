//
//  Splash.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // 전체 화면 배경
            Color.BackgroundBlack
                .ignoresSafeArea(.all)
            
            VStack {
                Spacer()
                    .frame(height: 260)

                Image("Splash_Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 190, height: 160)
                
                Spacer()
                    .frame(height: 87)
                
                Image("Splash_TextLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 55)

                Spacer()
                    .frame(height: 310)
            }
        }
    }
}

struct Splash_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
