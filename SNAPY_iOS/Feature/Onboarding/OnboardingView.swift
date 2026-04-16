//
//  OnboardingView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct OnboardingView: View {
    var onStartTap: () -> Void
    var body: some View {
        ZStack {
            Color.BackgroundBlack
                .ignoresSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Image("Login_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 34)
                    
                    Image("SNAPY_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 28)
                }
                .padding(.top, 34)
                .padding(.horizontal, 24)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("가장 나다운 모습을 찍어 SNAPY 찍어\n친구들에게 공유하세요!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textWhite)
                        .lineSpacing(12)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("전후면 카메라로 가장 나다운 모습 공유하기")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.textWhite)
                        .padding(.top, 12)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 50)
                
                Image("Onboarding_img")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 270, height: 410)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 66)
                
                
                Spacer()
                    .frame(height: 65)
                
                // 하단 버튼
                SnapyButton(title: "SNAPY 시작하기") {
                    withAnimation {
                        onStartTap()
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onStartTap: {})
    }
}

