//
//  SignUpHeader.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/20/26.
//

import SwiftUI

struct SignUpHeader: View {
    var onBack: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Image("Login_TextLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 25)
                
                HStack {
                    Button {
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.textWhite)
                    }
                    .buttonStyle(.glass)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
    }
}
