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

    private let thumbSize: CGFloat = 64

    var body: some View {
        HStack(spacing: 10) {
            // + 추가 버튼: 즉시 갤러리 표시
            Button {
                showPicker = true
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
        .photosPicker(isPresented: $showPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    previewImage = image
                    showAddView = true
                }
                // 동일한 사진을 다시 고를 수 있도록 초기화
                await MainActor.run { pickerItem = nil }
            }
        }
        .fullScreenCover(isPresented: $showAddView, onDismiss: {
            previewImage = nil
            // "다른 이미지 사용" 으로 닫혔으면 picker 를 다시 띄운다
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
