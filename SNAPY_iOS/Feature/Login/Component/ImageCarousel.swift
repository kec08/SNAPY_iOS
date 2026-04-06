//
//  ImageCarousel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/6/26.
//

import SwiftUI
import Combine

struct ImageCarousel: View {
    let images: [String]
    let autoScrollInterval: TimeInterval

    @State private var selectedIndex: Int = 0
    @State private var offset: CGFloat = 0
    @State private var isAnimating = false

    // 카드 크기
    private let selectedWidth: CGFloat = 201
    private let normalWidth: CGFloat = 159
    private let spacing: CGFloat = 24

    // 한 칸 이동 거리
    private var stepWidth: CGFloat {
        normalWidth + spacing
    }

    init(images: [String], autoScrollInterval: TimeInterval = 2.5) {
        self.images = images
        self.autoScrollInterval = autoScrollInterval
    }

    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geo in
                let centerX = geo.size.width / 2

                HStack(spacing: spacing) {
                    ForEach(0..<images.count, id: \.self) { index in
                        let isSelected = (index == selectedIndex)

                        Image(images[index])
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: isSelected ? selectedWidth : normalWidth,
                                height: isSelected ? 300 : 240
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black)
                                    .opacity(isSelected ? 0 : 0.5)
                            )
                            .animation(.easeInOut(duration: 0.4), value: selectedIndex)
                    }
                }
                // 첫 번째 카드를 중앙에 놓기 위한 초기 오프셋 + 이동량
                .offset(x: centerX - selectedWidth / 2 - CGFloat(selectedIndex) * stepWidth + offset)
                .animation(.easeInOut(duration: 0.5), value: selectedIndex)
            }
            .frame(height: 300)
            .clipped()

            // 페이지 인디케이터
            HStack(spacing: 8) {
                ForEach(0..<images.count, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedIndex ? Color.textWhite : Color.customGray500)
                        .frame(width: index == selectedIndex ? 12 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: selectedIndex)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .onReceive(Timer.publish(every: autoScrollInterval, on: .main, in: .common).autoconnect()) { _ in
            guard !isAnimating else { return }
            advanceToNext()
        }
    }

    private func advanceToNext() {
        isAnimating = true
        selectedIndex = (selectedIndex + 1) % images.count
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = false
        }
    }
}
