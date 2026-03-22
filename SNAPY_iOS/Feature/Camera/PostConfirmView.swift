import SwiftUI

struct PostConfirmView: View {
    @EnvironmentObject var cameraVM: CameraViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("오늘의 멋진 추억을 게시할까요?")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 40)

            Spacer()

            // Horizontal scroll of captured photos
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<cameraVM.capturedPhotos.count, id: \.self) { index in
                        let photo = cameraVM.capturedPhotos[index]

                        ZStack {
                            // Back image
                            if let backImage = photo.back {
                                Image(uiImage: backImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 250, height: 340)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(Color(white: 0.15))
                                    .frame(width: 250, height: 340)
                            }

                            // 촬영한 이미지 미리보기
                            VStack {
                                HStack {
                                    if let frontImage = photo.front {
                                        Image(uiImage: frontImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 70, height: 90)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(color: .black.opacity(0.5), radius: 3)
                                    } else {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(white: 0.25))
                                            .frame(width: 70, height: 90)
                                    }
                                    Spacer()
                                }
                                .padding(10)
                                Spacer()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            // Loading indicator
            if cameraVM.isUploading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.bottom, 16)
            }

            Button {
                Task { await cameraVM.uploadPhotos() }
            } label: {
                Text("게시하기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .disabled(cameraVM.isUploading)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
