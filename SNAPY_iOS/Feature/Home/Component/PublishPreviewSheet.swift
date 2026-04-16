//
//  PublishPreviewSheet.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/16/26.
//

import SwiftUI

struct PublishPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var photoStore = PhotoStore.shared

    @State private var currentPage = 0

    private var todayPhotos: [PhotoData] {
        photoStore.todayAlbum?.photos ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundBlack.ignoresSafeArea()

                if todayPhotos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(.customGray300)
                        Text("오늘 찍은 사진이 없습니다")
                            .font(.system(size: 16))
                            .foregroundColor(.customGray300)
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("오늘의 사진 \(todayPhotos.count)장")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top, 12)

                        // 사진 미리보기
                        TabView(selection: $currentPage) {
                            ForEach(Array(todayPhotos.enumerated()), id: \.element.id) { index, photo in
                                if let urlString = photo.backImageUrl,
                                   let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: .infinity)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        case .failure:
                                            placeholderView
                                        case .empty:
                                            ProgressView()
                                                .frame(maxWidth: .infinity, maxHeight: 400)
                                        @unknown default:
                                            placeholderView
                                        }
                                    }
                                    .tag(index)
                                } else {
                                    placeholderView
                                        .tag(index)
                                }
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 420)
                        .padding(.horizontal, 16)

                        // 페이지 인디케이터 텍스트
                        Text("\(currentPage + 1) / \(todayPhotos.count)")
                            .font(.system(size: 13))
                            .foregroundColor(.customGray300)

                        Spacer()

                        // 게시 버튼
                        Button {
                            // 게시 로직 (임시)
                            dismiss()
                        } label: {
                            Text("게시하기")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.backgroundBlack)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.MainYellow, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("게시 확인")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.backgroundBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.large])
        .task {
            await photoStore.loadToday()
        }
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.08))
            .frame(maxWidth: .infinity)
            .frame(height: 400)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(.customGray300)
            )
    }
}
