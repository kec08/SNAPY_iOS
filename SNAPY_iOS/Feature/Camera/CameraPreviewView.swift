import SwiftUI
import AVFoundation

//UIViewRepresentable 로 감싸 SwiftUI에서도 프리뷰 처리
struct CameraPreviewView: UIViewRepresentable {
    // UIKit 카메라 레이어를 SwiftUI로 브릿징
    let previewLayer: AVCaptureVideoPreviewLayer?

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        if let previewLayer = previewLayer {
            view.previewLayer = previewLayer
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        // 기존 프리뷰 레이어가 다르면 교체
        if uiView.previewLayer !== previewLayer {
            uiView.previewLayer?.removeFromSuperlayer()
            uiView.previewLayer = previewLayer
            if let previewLayer = previewLayer {
                previewLayer.videoGravity = .resizeAspectFill
                uiView.layer.addSublayer(previewLayer)
            }
        }
        // frame 업데이트
        previewLayer?.frame = uiView.bounds
    }
}

// layoutSubviews에서 frame을 자동 갱신하는 커스텀 UIView
class PreviewUIView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        // 레이아웃이 변경될 때마다 프리뷰 레이어 크기를 맞춤
        previewLayer?.frame = bounds
    }
}
