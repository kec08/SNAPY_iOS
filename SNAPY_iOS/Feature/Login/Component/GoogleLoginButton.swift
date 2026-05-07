//
//  GoogleLoginButton.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import SwiftUI

struct GoogleLoginButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.textWhite)

                HStack {
                    Image("Google_LoginLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
        .padding(.horizontal, 24)
    }
}

struct GoogleLoginButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GoogleLoginButton(title: "Google로 계속하기", action: {})
        }
    }
}
