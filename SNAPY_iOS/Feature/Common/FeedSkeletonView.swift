//
//  FeedSkeletonView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/7/26.
//

import SwiftUI

// MARK: - 피드 스켈레톤 카드

struct FeedSkeletonCard: View {
    @State private var shimmer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 프로필 헤더
            HStack(spacing: 10) {
                Circle()
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 80, height: 12)
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 50, height: 10)
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            // 사진 영역
            RoundedRectangle(cornerRadius: 12)
                .frame(height: 420)
                .padding(.horizontal, 16)

            // 하트 + 댓글 버튼 영역
            HStack(spacing: 16) {
                Circle()
                    .frame(width: 28, height: 28)
                Circle()
                    .frame(width: 28, height: 28)
                Spacer()
            }
            .padding(.horizontal, 16)

            // 이미지 댓글 영역
            HStack(spacing: 12) {
                Circle()
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundColor(.clear)
                    )
                Circle()
                    .frame(width: 44, height: 44)
                Circle()
                    .frame(width: 44, height: 44)
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .foregroundColor(Color.white.opacity(0.08))
        .overlay(
            shimmerOverlay
                .mask(
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Circle().frame(width: 40, height: 40)
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4).frame(width: 80, height: 12)
                                RoundedRectangle(cornerRadius: 4).frame(width: 50, height: 10)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        RoundedRectangle(cornerRadius: 12)
                            .frame(height: 420)
                            .padding(.horizontal, 16)

                        HStack(spacing: 16) {
                            Circle().frame(width: 28, height: 28)
                            Circle().frame(width: 28, height: 28)
                            Spacer()
                        }
                        .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            Circle().frame(width: 44, height: 44)
                            Circle().frame(width: 44, height: 44)
                            Circle().frame(width: 44, height: 44)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmer = true
            }
        }
    }

    private var shimmerOverlay: some View {
        GeometryReader { geo in
            let width = geo.size.width
            LinearGradient(
                colors: [
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 0.6)
            .offset(x: shimmer ? width * 1.2 : -width * 0.6)
        }
    }
}

// MARK: - 피드 스켈레톤 리스트 (2개 카드)

struct FeedSkeletonList: View {
    var body: some View {
        VStack(spacing: 30) {
            FeedSkeletonCard()
            FeedSkeletonCard()
        }
    }
}

#Preview {
    ZStack {
        Color.backgroundBlack.ignoresSafeArea()
        ScrollView {
            FeedSkeletonList()
        }
    }
}
