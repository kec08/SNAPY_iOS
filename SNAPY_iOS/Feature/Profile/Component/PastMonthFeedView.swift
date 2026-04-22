//
//  PastMonthFeedView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/22/26.
//

import SwiftUI

struct PastMonthFeedView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let month: Int
    let year: Int

    @Environment(\.dismiss) private var dismiss
    @State private var posts: [FeedPost] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.white)
            } else if posts.isEmpty {
                VStack(spacing: 12) {
                    Image("Crying_img")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    Text("게시물이 없습니다")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.customGray300)
                }
            } else {
                ScrollView {
                    ProfileFeedGrid(
                        posts: posts,
                        displayName: viewModel.username,
                        handle: viewModel.handle,
                        profileImage: viewModel.profileImage
                    )
                    .padding(.top, 8)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textWhite)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("\(month)월 게시물")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textWhite)
            }
        }
        .toolbarBackground(Color.backgroundBlack, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            posts = await viewModel.loadMonthFeed(month: month)
            isLoading = false
        }
    }
}
