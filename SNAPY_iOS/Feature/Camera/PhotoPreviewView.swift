import SwiftUI

struct PhotoPreviewView: View {
    @EnvironmentObject var cameraVM: CameraViewModel

    private var lastPhoto: (front: UIImage?, back: UIImage?)? {
        cameraVM.capturedPhotos.last
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("사진 촬영 완료! 계속 하시겠습니까?")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.top, 20)

            Spacer()

            // 듀얼캠
            ZStack {
                // 후면 카메라
                if let backImage = lastPhoto?.back {
                    Image(uiImage: backImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 350, height: 500)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.15))
                }

                // 전면 카메라
                VStack {
                    HStack {
                        if let frontImage = lastPhoto?.front {
                            Image(uiImage: frontImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .black.opacity(0.5), radius: 5)
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(white: 0.25))
                                .frame(width: 100, height: 130)
                        }
                        Spacer()
                    }
                    .padding(12)
                    Spacer()
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .padding(.horizontal, 16)

            Spacer()

            // 다시 찍기 버튼
            HStack {
                Button {
                    cameraVM.retakePhoto()
                } label: {
                    Text("다시찍기")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    cameraVM.savePhoto()
                } label: {
                    Text("저장하기")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
