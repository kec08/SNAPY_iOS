//
//  GuestbookSection.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI

struct GuestbookSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showAddSheet = false
    @State private var showFullView = false

    private let thumbSize: CGFloat = 64

    var body: some View {
        HStack(spacing: 10) {
            // + 추가 버튼
            Button {
                showAddSheet = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.18))
                        .frame(width: thumbSize, height: thumbSize)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.textWhite)
                }
            }

            // 가로 썸네일 (앞쪽 3개 미리보기)
            HStack(spacing: 6) {
                ForEach(Array(viewModel.guestbookEntries.prefix(3))) { entry in
                    Button {
                        showFullView = true
                    } label: {
                        guestbookThumbnail(for: entry)
                            .frame(width: thumbSize, height: thumbSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Spacer(minLength: 0)

            // 전체보기 화살표
            Button {
                showFullView = true
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.customGray300)
                    .frame(width: 28, height: thumbSize)
            }
        }
        .padding(.horizontal, 16)
        .fullScreenCover(isPresented: $showAddSheet) {
            GuestbookAddView { image in
                viewModel.addGuestbookImage(image)
            }
        }
        .navigationDestination(isPresented: $showFullView) {
            GuestbookFullView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func guestbookThumbnail(for entry: GuestbookEntry) -> some View {
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let name = entry.assetName {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            Color(white: 0.2)
        }
    }
}

struct GuestbookSection_Previews: PreviewProvider {
    static var previews: some View {
        GuestbookSection(viewModel: ProfileViewModel())
            .background(Color.backgroundBlack)
    }
}
