import SwiftUI

struct PhotoPreviewView: View {
    @EnvironmentObject var cameraVM: CameraViewModel

    private var lastPhoto: (front: UIImage?, back: UIImage?)? {
        cameraVM.capturedPhotos.last
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(cameraVM.capturedTimeText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 40)

            Spacer()
                .frame(height: 30)

            // 듀얼캠
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    // 후면 카메라 (메인)
                    if let backImage = lastPhoto?.back {
                        Image(uiImage: backImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.15))
                    }

                    // 전면 카메라 (드래그 가능)
                    if let frontImage = lastPhoto?.front {
                        DraggablePIP(
                            containerSize: geo.size,
                            pipWidth: 120,
                            pipHeight: 160,
                            padding: 12
                        ) {
                            Image(uiImage: frontImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .padding(.horizontal, 16)

            Spacer()

            // 다시 찍기 / 저장하기 버튼
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
