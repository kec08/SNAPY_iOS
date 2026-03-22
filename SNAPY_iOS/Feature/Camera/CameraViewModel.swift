//
//  CameraViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

// showPreview = false, showPostConfirm = false  →  CameraView (촬영 화면)
// showPreview = true,  showPostConfirm = false  →  PhotoPreviewView (미리보기)
// showPreview = false, showPostConfirm = true   →  PostConfirmView (게시 확인)

import Foundation
import SwiftUI
import AVFoundation
import Combine
import Photos

@MainActor
final class CameraViewModel: ObservableObject {
    @Published var capturedPhotos: [(front: UIImage?, back: UIImage?)] = []
    @Published var currentPhotoIndex = 0
    @Published var isCameraReady = false
    @Published var showPreview = false
    @Published var showPostConfirm = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var latestBackImage: UIImage?
    @Published var latestFrontImage: UIImage?
    @Published var backPreviewLayer: AVCaptureVideoPreviewLayer?
    @Published var frontPreviewLayer: AVCaptureVideoPreviewLayer?

    let dualCamera = DualCameraService()
    let maxPhotos = 5
    private var cancellables = Set<AnyCancellable>()

    var photoCountText: String {
        "\(capturedPhotos.count)/\(maxPhotos)"
    }

//    var currentTimeSlotText: String {
//        Date().currentTimeSlot.displayName
//    }

    init() {
        // Observe camera images
        dualCamera.$backCameraImage
            .receive(on: DispatchQueue.main)
            .assign(to: &$latestBackImage)

        dualCamera.$frontCameraImage
            .receive(on: DispatchQueue.main)
            .assign(to: &$latestFrontImage)

        dualCamera.$backPreviewLayer
            .receive(on: DispatchQueue.main)
            .assign(to: &$backPreviewLayer)

        dualCamera.$frontPreviewLayer
            .receive(on: DispatchQueue.main)
            .assign(to: &$frontPreviewLayer)
    }
    // 카메라 권한 체크
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraReady = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraReady = granted
                    if granted { self?.setupCamera() }
                }
            }
        default:
            isCameraReady = false
            errorMessage = "카메라 권한이 필요합니다. 설정에서 카메라 접근을 허용해주세요."
        }
    }

    private func setupCamera() {
        dualCamera.setupSession()
        // Small delay to allow session configuration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.dualCamera.startSession()
        }
    }

    func capturePhoto() {
        guard capturedPhotos.count < maxPhotos else { return }

        if dualCamera.isMultiCamSupported && dualCamera.isRunning {
            dualCamera.capturePhotos { [weak self] backImage, frontImage in
                DispatchQueue.main.async {
                    // 촬영 실패 시 (연결 끊김 등) 무시
                    guard backImage != nil || frontImage != nil else { return }
                    self?.capturedPhotos.append((front: frontImage, back: backImage))
                    DispatchQueue.main.async {
                        self?.showPreview = true
                    }
                }
            }
        } else {
            // Simulator fallback - use placeholder images
            let placeholderBack = createPlaceholderImage(text: "후면 \(capturedPhotos.count + 1)", color: .darkGray)
            let placeholderFront = createPlaceholderImage(text: "전면 \(capturedPhotos.count + 1)", color: .gray)
            capturedPhotos.append((front: placeholderFront, back: placeholderBack))
            DispatchQueue.main.async { [weak self] in
                self?.showPreview = true
            }
        }
    }

    func retakePhoto() {
        if !capturedPhotos.isEmpty {
            capturedPhotos.removeLast()
        }
        showPreview = false
    }

    func confirmPhoto() {
        showPreview = false
    }

    func proceedToPost() {
        showPreview = false
        showPostConfirm = true
        dualCamera.stopSession()
    }

    @Published var uploadComplete = false

    func uploadPhotos() async {
        isUploading = true

        // PhotoStore에 사진 저장
        // PhotoStore.shared.savePhotos(capturedPhotos)
        // 서버에 업로드 하기 위해 0.5초 대기
        try? await Task.sleep(nanoseconds: 500_000_000)
        isUploading = false
        uploadComplete = true
    }

    func resetCamera() {
        capturedPhotos = []
        currentPhotoIndex = 0
        showPreview = false
        showPostConfirm = false
        uploadComplete = false
        latestBackImage = nil
        latestFrontImage = nil
        setupCamera()
    }

    func stopCamera() {
        dualCamera.stopSession()
    }

    private func createPlaceholderImage(text: String, color: UIColor) -> UIImage {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 20, weight: .bold)
            ]
            let string = NSString(string: text)
            let textSize = string.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            string.draw(in: textRect, withAttributes: attrs)
        }
    }
}
