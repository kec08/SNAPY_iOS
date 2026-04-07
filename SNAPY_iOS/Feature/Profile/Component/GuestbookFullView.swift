//
//  GuestbookFullView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import PhotosUI

struct GuestbookFullView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    // 갤러리 → 미리보기 작성 흐름
    @State private var showPicker = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var showAddView = false
    @State private var requestNewImageAfterDismiss = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollView {
                // 셀 사이 세로 간격은 프로필 오버플로우(셀 밖으로 나옴)를 고려해 충분히 확보
                LazyVGrid(columns: columns, spacing: 28) {
                    ForEach(viewModel.guestbookEntries) { entry in
                        guestbookCell(for: entry)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 12)
                .padding(.bottom, 120)
            }

            // 하단 우측 플로팅 연필 버튼: 즉시 갤러리 표시
            Button {
                showPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.18))
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                    Image("Pen_icon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.textWhite)
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 32)
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
                Text("방문록")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textWhite)
            }
        }
        .toolbarBackground(Color.backgroundBlack, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
    }

    // 가로로 긴 16:9 셀 + 셀 밖 가운데 하단으로 약간 벗어난 원형 프로필
    @ViewBuilder
    private func guestbookCell(for entry: GuestbookEntry) -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = w * 9 / 16

            ZStack {
                thumbnail(for: entry)
                    .frame(width: w, height: h)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(width: w, height: h)
            .overlay(alignment: .bottom) {
                authorAvatar(for: entry)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.backgroundBlack))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.backgroundBlack, lineWidth: 2))
                    .offset(y: 13) // 셀 밖으로 절반 정도 벗어나게
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
    }

    @ViewBuilder
    private func thumbnail(for entry: GuestbookEntry) -> some View {
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

#Preview {
    NavigationStack {
        GuestbookFullView(viewModel: ProfileViewModel())
    }
}
