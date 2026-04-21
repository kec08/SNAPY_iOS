//
//  ImageViewerView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import Kingfisher

struct ImageViewerView: View {
    let image: UIImage?
    let imageUrl: String?
    let assetName: String
    var horizontalPadding: CGFloat = 0
    var isCircle: Bool = false          // true: 프로필(원형), false: 배너(직사각)

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 확대/축소 + 드래그 가능한 이미지
            Group {
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let url = imageUrl, let imgUrl = URL(string: url) {
                    KFImage(imgUrl)
                        .resizable()
                        .placeholder { Color.customDarkGray.overlay(ProgressView().tint(.white)) }
                        .fade(duration: 0.2)
                        .scaledToFill()
                } else {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(
                width: isCircle ? 300 : nil,
                height: isCircle ? 300 : 230
            )
            .frame(maxWidth: isCircle ? nil : .infinity)
            .clipShape(isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 16)))
            .padding(.horizontal, horizontalPadding)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                // 핀치 줌
                MagnifyGesture()
                    .onChanged { value in
                        scale = lastScale * value.magnification
                    }
                    .onEnded { _ in
                        lastScale = scale
                        // 최소 1배
                        if scale < 1.0 {
                            withAnimation(.spring()) {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                    }
            )
            .simultaneousGesture(
                // 드래그 (확대 시)
                DragGesture()
                    .onChanged { value in
                        if scale > 1.0 {
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                    }
                    .onEnded { _ in
                        lastOffset = offset
                        if scale <= 1.0 {
                            withAnimation(.spring()) {
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                    }
            )
            .simultaneousGesture(
                // 더블 탭 줌
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2
                                lastScale = 2
                            }
                        }
                    }
            )

            // 닫기 버튼
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }
                Spacer()
            }
        }
    }
}
