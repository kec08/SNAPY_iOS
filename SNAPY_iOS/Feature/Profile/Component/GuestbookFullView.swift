//
//  GuestbookFullView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI

struct GuestbookFullView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddSheet = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.backgroundBlack.ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(viewModel.guestbookEntries) { entry in
                        GeometryReader { geo in
                            thumbnail(for: entry)
                                .frame(width: geo.size.width, height: geo.size.width)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            // 하단 우측 플로팅 연필 버튼
            Button {
                showAddSheet = true
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
        .fullScreenCover(isPresented: $showAddSheet) {
            GuestbookAddView { image in
                viewModel.addGuestbookImage(image)
            }
        }
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
}

#Preview {
    NavigationStack {
        GuestbookFullView(viewModel: ProfileViewModel())
    }
}
