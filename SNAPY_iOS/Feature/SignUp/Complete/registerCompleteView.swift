//
//  registerCompleteView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/19/26.
//

import SwiftUI

struct registerCompleteView: View {
    var onDoneTap: () -> Void
    
    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                
                HStack {
                    Spacer()
                    
                    Image("Login_TextLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 25)
                    
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                
                Spacer()
                    .frame(height: 80)
                
                VStack(spacing: 20) {
                    Image("Complete_img")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 167, height: 235)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    VStack(spacing: 12) {
                        Text("회원가입 완료!")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("SNAPY를 즐길 준비 되셨나요?")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                SignUpButton(
                    title: "준비 완료"
                ) {
                    onDoneTap()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        registerCompleteView(onDoneTap: {})
    }
}
