//
//  GuestbookAddView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI
@preconcurrency import AVFoundation
import PhotosUI
import Combine

// 방명록 추가 화면: 카메라 프리뷰 + 촬영(Pen_icon) / 갤러리(Img_icon) 버튼
struct GuestbookAddView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = GuestbookCameraService()
    @State private var galleryItem: PhotosPickerItem?
    @State private var capturedPreview: UIImage?

    let onPicked: (UIImage) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 카메라 프리뷰
            if let layer = camera.previewLayer {
                GuestbookCameraPreview(previewLayer: layer)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.4))
                    Text(camera.statusText)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // 캡처 미리보기 (촬영 직후)
            if let preview = capturedPreview {
                Color.black.ignoresSafeArea()
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            }

            // 상/하단 컨트롤
            VStack {
                // 상단: 닫기
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                    Spacer()
                    Text("방명록 추가")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    // 균형용 자리
                    Color.clear.frame(width: 42, height: 42)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // 하단 컨트롤
                if let preview = capturedPreview {
                    // 촬영 완료 후 확정/재촬영
                    HStack(spacing: 24) {
                        Button {
                            capturedPreview = nil
                        } label: {
                            Text("다시 찍기")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color.white.opacity(0.18)))
                        }

                        Button {
                            onPicked(preview)
                            dismiss()
                        } label: {
                            Text("방명록 남기기")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color.white))
                        }
                    }
                    .padding(.bottom, 40)
                } else {
                    HStack {
                        Spacer()

                        // 촬영 버튼 (Pen_icon)
                        Button {
                            camera.capture { image in
                                if let image { capturedPreview = image }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 78, height: 78)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 64, height: 64)
                                Image("Pen_icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 26, height: 26)
                                    .foregroundColor(.black)
                            }
                        }

                        Spacer()
                    }
                    .overlay(alignment: .trailing) {
                        // 갤러리 버튼 (Img_icon)
                        PhotosPicker(selection: $galleryItem, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 52, height: 52)
                                Image("Img_icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 32)
                    }
                    .padding(.bottom, 48)
                }
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: galleryItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedPreview = image
                }
                galleryItem = nil
            }
        }
    }
}

// MARK: - Camera service (단일 후면 카메라, 최소 구현)
//
// 세션/입출력은 백그라운드 큐(sessionQueue)에서만 다루기 때문에
// 클래스 자체는 @MainActor 가 아닌 nonisolated 로 두고,
// UI에 노출되는 @Published 프로퍼티만 메인 액터에서 갱신한다.

final class GuestbookCameraService: NSObject, ObservableObject, @unchecked Sendable {
    @MainActor @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @MainActor @Published var statusText: String = "카메라 준비 중..."

    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "guestbook.camera.session")
    private var captureCompletion: ((UIImage?) -> Void)?

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.configureAndRun()
                } else {
                    Task { @MainActor in self.statusText = "카메라 권한이 필요합니다" }
                }
            }
        default:
            Task { @MainActor in self.statusText = "카메라 권한이 필요합니다" }
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            session.stopRunning()
        }
    }

    func capture(_ completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        sessionQueue.async { [output] in
            let settings = AVCapturePhotoSettings()
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureAndRun() {
        sessionQueue.async { [weak self, session, output] in
            guard let self else { return }
            session.beginConfiguration()
            session.sessionPreset = .photo

            // 입력 (후면 카메라)
            if session.inputs.isEmpty,
               let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let input = try? AVCaptureDeviceInput(device: device),
               session.canAddInput(input) {
                session.addInput(input)
            }

            // 출력
            if session.outputs.isEmpty, session.canAddOutput(output) {
                session.addOutput(output)
            }

            session.commitConfiguration()
            session.startRunning()

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            Task { @MainActor in
                self.previewLayer = layer
                self.statusText = ""
            }
        }
    }
}

extension GuestbookCameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        let image: UIImage? = {
            guard let data = photo.fileDataRepresentation() else { return nil }
            return UIImage(data: data)
        }()
        let completion = self.captureCompletion
        self.captureCompletion = nil
        Task { @MainActor in
            completion?(image)
        }
    }
}

// MARK: - Preview layer host

struct GuestbookCameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewContainer {
        let view = PreviewContainer()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: PreviewContainer, context: Context) {
        previewLayer.frame = uiView.bounds
    }

    final class PreviewContainer: UIView {
        override func layoutSubviews() {
            super.layoutSubviews()
            layer.sublayers?.forEach { $0.frame = bounds }
        }
    }
}
