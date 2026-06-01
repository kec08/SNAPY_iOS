//
//  FriendSkeletonView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/10/26.
//

import SwiftUI

// MARK: - 친구 스켈레톤 Row

struct FriendSkeletonRow: View {
    @State private var shimmer = false

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 90, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 60, height: 11)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .frame(width: 72, height: 32)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .foregroundColor(Color.white.opacity(0.08))
        .overlay(
            shimmerOverlay
                .mask(
                    HStack(spacing: 14) {
                        Circle().frame(width: 50, height: 50)
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 4).frame(width: 90, height: 14)
                            RoundedRectangle(cornerRadius: 4).frame(width: 60, height: 11)
                        }
                        Spacer()
                        RoundedRectangle(cornerRadius: 8).frame(width: 72, height: 32)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
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

// MARK: - 친구 스켈레톤 리스트

struct FriendSkeletonList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 4)
                .frame(width: 60, height: 13)
                .foregroundColor(Color.white.opacity(0.08))
                .padding(.horizontal, 22)
                .padding(.bottom, 12)

            ForEach(0..<12, id: \.self) { _ in
                FriendSkeletonRow()
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - 프로필 피드 스켈레톤

struct ProfileFeedSkeletonGrid: View {
    var count: Int = 12
    @State private var shimmer = false

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<count, id: \.self) { _ in
                Color.white.opacity(0.08)
                    .aspectRatio(3.0/4.0, contentMode: .fit)
            }
        }
        .overlay(
            shimmerOverlay
                .mask(
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(0..<count, id: \.self) { _ in
                            Color.white
                                .aspectRatio(3.0/4.0, contentMode: .fit)
                        }
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

#Preview("FriendSkeleton") {
    ZStack {
        Color.black.ignoresSafeArea()
        ScrollView {
            FriendSkeletonList()
        }
    }
}

#Preview("ProfileFeedSkeleton") {
    ZStack {
        Color.black.ignoresSafeArea()
        ProfileFeedSkeletonGrid()
    }
}
