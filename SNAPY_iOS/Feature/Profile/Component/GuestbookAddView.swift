//
//  GuestbookAddView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI

struct GuestbookAddView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let onPicked: (UIImage) -> Void
    let onRequestNewImage: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer(minLength: 16)
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 600)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .padding(.horizontal, 24)

                // 다른 이미지 사용 → 부모에 알리고 dismiss
                Button {
                    onRequestNewImage()
                    dismiss()
                } label: {
                    Text("다른 이미지 사용")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                }

                Spacer(minLength: 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundBlack.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("방명록 작성")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onPicked(image)
                        dismiss()
                    } label: {
                        Text("작성")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color.backgroundBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    GuestbookAddView(
        image: UIImage(systemName: "photo")!,
        onPicked: { _ in },
        onRequestNewImage: { }
    )
}
