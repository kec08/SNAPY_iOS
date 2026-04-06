//
//  GuestbookSection.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI

struct GuestbookSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("방명록")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textWhite)
                Spacer()
                Button("전체보기") {}
                    .font(.system(size: 13))
                    .foregroundColor(.customGray300)
            }
            .padding(.horizontal, 16)

            // 방명록 placeholder
            VStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { _ in
                    guestbookPlaceholder
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var guestbookPlaceholder: some View {
        HStack(spacing: 12) {
            // 펭귄 프사
            Image("Profile_img")
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.25))
                    .frame(width: 80, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(white: 0.2))
                    .frame(height: 12)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}

struct GuestbookSection_Previews: PreviewProvider {
    static var previews: some View {
        GuestbookSection()
    }
}
