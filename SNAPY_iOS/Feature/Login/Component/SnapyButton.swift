//
//  SNAPYButton.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI

struct SnapyButton: View {
    let title: String
    var isEnabled: Bool = true
    var style: SnapyButtonStyle = .primary
    let action: () -> Void

    enum SnapyButtonStyle {
        case primary
        case secondary
        case destructive
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)

                HStack {
                    Image("Login_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                        .padding(.leading, 20)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isEnabled ? Color.textWhite : Color.customGray500)
            .foregroundColor(isEnabled ? Color.backgroundBlack : Color.customGray300)
            .cornerRadius(28)
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 24)
    }
}

struct SnapyButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            SnapyButton(title: "SNAPY로 계속하기", action: {})
        }
    }
}
