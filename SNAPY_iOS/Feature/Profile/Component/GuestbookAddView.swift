//
//  GuestbookAddView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
import PhotosUI

// 방명록 추가 화면: 갤러리에서 사진을 골라 미리보기 후 우상단 "작성" 으로 등록
struct GuestbookAddView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var galleryItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showPicker = false

    let onPicked: (UIImage) -> Void

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: 헤더 (좌: 뒤로가기, 중: 타이틀, 우: 작성 버튼)
                ZStack {
                    Text("방명록 작성")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Button {
                            guard let img = pickedImage else { return }
                            onPicked(img)
                            dismiss()
                        } label: {
                            Text("작성")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(pickedImage == nil ? .white.opacity(0.3) : .white)
                        }
                        .disabled(pickedImage == nil)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // MARK: 본문 (선택된 이미지 미리보기 / 비어있으면 안내)
                if let img = pickedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundColor(.white.opacity(0.4))
                        Text("방명록에 남길 사진을 선택해주세요")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))

                        Button {
                            showPicker = true
                        } label: {
                            Text("사진 선택")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color.white))
                        }
                    }
                }

                Spacer()

                // 다른 사진으로 다시 선택
                if pickedImage != nil {
                    Button {
                        showPicker = true
                    } label: {
                        Text("다른 사진 선택")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $galleryItem, matching: .images)
        .onAppear {
            // 진입 시 자동으로 갤러리 열기
            if pickedImage == nil {
                showPicker = true
            }
        }
        .onChange(of: galleryItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pickedImage = image
                }
            }
        }
    }
}

#Preview {
    GuestbookAddView { _ in }
}
