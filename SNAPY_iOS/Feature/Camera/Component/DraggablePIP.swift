//
//  DraggablePIP.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/1/26.
//

import SwiftUI

/// 4개 모서리 위치
enum PIPCorner {
    case topLeading, topTrailing, bottomLeading, bottomTrailing
}

/// 드래그 가능한 작은 카메라 화면 (Picture-in-Picture)
/// CameraView, PhotoPreviewView, AlbumPhotoCard에서 공통 사용
struct DraggablePIP<Content: View>: View {
    let containerSize: CGSize   // 부모(후면 사진)의 크기
    let pipWidth: CGFloat
    let pipHeight: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    @State private var currentCorner: PIPCorner = .topLeading
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        content()
            .frame(width: pipWidth, height: pipHeight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.5), radius: 5)
            .offset(x: cornerPosition.x + dragOffset.width,
                    y: cornerPosition.y + dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        // 현재 위치 계산 (모서리 기준 + 드래그 이동량)
                        let finalX = cornerPosition.x + value.translation.width
                        let finalY = cornerPosition.y + value.translation.height

                        // PIP 중심점
                        let centerX = finalX + pipWidth / 2
                        let centerY = finalY + pipHeight / 2

                        // 컨테이너 중심 기준으로 가장 가까운 모서리 계산
                        let midX = containerSize.width / 2
                        let midY = containerSize.height / 2

                        let newCorner: PIPCorner
                        if centerX < midX && centerY < midY {
                            newCorner = .topLeading
                        } else if centerX >= midX && centerY < midY {
                            newCorner = .topTrailing
                        } else if centerX < midX && centerY >= midY {
                            newCorner = .bottomLeading
                        } else {
                            newCorner = .bottomTrailing
                        }

                        // 스프링 애니메이션으로 모서리에 붙기
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            currentCorner = newCorner
                            dragOffset = .zero
                        }
                    }
            )
            .animation(isDragging ? nil : .spring(response: 0.35, dampingFraction: 0.7), value: currentCorner)
    }

    /// 각 모서리별 offset 위치 계산
    private var cornerPosition: CGPoint {
        switch currentCorner {
        case .topLeading:
            return CGPoint(x: padding, y: padding)
        case .topTrailing:
            return CGPoint(x: containerSize.width - pipWidth - padding, y: padding)
        case .bottomLeading:
            return CGPoint(x: padding, y: containerSize.height - pipHeight - padding)
        case .bottomTrailing:
            return CGPoint(x: containerSize.width - pipWidth - padding, y: containerSize.height - pipHeight - padding)
        }
    }
}
