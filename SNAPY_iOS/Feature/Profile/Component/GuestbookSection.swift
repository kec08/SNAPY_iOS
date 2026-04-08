//
//  GuestbookSection.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import PhotosUI

struct GuestbookSection: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showFullView = false

    // 갤러리 → 미리보기 작성 흐름
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var showAddView = false
    @State private var requestNewImageAfterDismiss = false

    private let thumbWidth: CGFloat = 55
    private var thumbHeight: CGFloat { thumbWidth * 16 / 9 }

    var body: some View {
        HStack(spacing: 12) {
            // + 추가 버튼
            Button {
                showPicker = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(white: 0.14))
                        .frame(width: thumbWidth, height: thumbHeight)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.textWhite)
                }
            }

            // 가로 썸네일
            HStack(spacing: 12) {
                ForEach(Array(viewModel.guestbookEntries.prefix(4))) { entry in
                    Button {
                        showFullView = true
                    } label: {
                        guestbookCell(for: entry)
                    }
                }
            }
            .padding(.trailing, 4)

            // 전체보기 화살표
            Button {
                showFullView = true
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textWhite)
                    .frame(width: 20, height: thumbHeight)
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    previewImage = image
                    showAddView = true
                }
                await MainActor.run { pickerItem = nil }
            }
        }
        .fullScreenCover(isPresented: $showAddView, onDismiss: {
            previewImage = nil
            if requestNewImageAfterDismiss {
                requestNewImageAfterDismiss = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showPicker = true
                }
            }
        }) {
            if let image = previewImage {
                GuestbookAddView(
                    image: image,
                    onPicked: { picked in
                        viewModel.addGuestbookImage(picked)
                    },
                    onRequestNewImage: {
                        requestNewImageAfterDismiss = true
                    }
                )
            }
        }
        .navigationDestination(isPresented: $showFullView) {
            GuestbookFullView(viewModel: viewModel)
        }
    }

    // 9:16 셀 + 하단 아바타 오버플로우
    @ViewBuilder
    private func guestbookCell(for entry: GuestbookEntry) -> some View {
        ZStack {
            guestbookThumbnail(for: entry)
                .frame(width: thumbWidth, height: thumbHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(width: thumbWidth, height: thumbHeight)
        .overlay(alignment: .bottom) {
            authorAvatar(for: entry)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.backgroundBlack))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.backgroundBlack, lineWidth: 2))
                .offset(y: 10)
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

    @ViewBuilder
    private func authorAvatar(for entry: GuestbookEntry) -> some View {
        if let image = entry.authorProfileImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let name = entry.authorProfileAsset {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            Image("Profile_img")
                .resizable()
                .scaledToFill()
        }
    }
}

struct GuestbookSection_Previews: PreviewProvider {
    static var previews: some View {
        GuestbookSection(viewModel: ProfileViewModel())
    }
}
