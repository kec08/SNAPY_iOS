
//
//  CameraView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var cameraVM: CameraViewModel
    @ViewBuilder
    private func cameraPlaceholder(text: String, isMain: Bool) -> some View {
        RoundedRectangle(cornerRadius: isMain ? 16 : 10)
            .fill(Color(white: isMain ? 0.1 : 0.2))
            .overlay(
                VStack(spacing: isMain ? 8 : 4) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.gray.opacity(isMain ? 0.5 : 1))
                        .font(.system(size: isMain ? 48 : 18))
                    Text(text)
                        .foregroundColor(.gray)
                        .font(.system(size: isMain ? 14 : 11))
                }
            )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            cameraContentView
                .opacity(cameraVM.showPreview ? 0 : 1)
                .allowsHitTesting(!cameraVM.showPreview)

            if cameraVM.showPreview {
                PhotoPreviewView()
                    .environmentObject(cameraVM)
            }
        }
        .onAppear {
            cameraVM.checkCameraPermission()
        }
        .onDisappear {
            cameraVM.stopCamera()
        }
    }

    private var cameraContentView: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("추억이 남을 사진을 찍어보세요!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                HStack {
                    Button {
                        cameraVM.shouldDismiss = true
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.textWhite)
                    }
                    .buttonStyle(.glass)

                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)

            Spacer()

            // 멀티캠 화면
            GeometryReader { geo in
                let isSwapped = cameraVM.isCameraSwapped

                // 후면 카메라 (메인)
                Group {
                    if let backLayer = cameraVM.backPreviewLayer {
                        CameraPreviewView(previewLayer: backLayer)
                            .clipShape(RoundedRectangle(cornerRadius: isSwapped ? 10 : 16))
                    } else {
                        cameraPlaceholder(text: "후면 카메라", isMain: !isSwapped)
                    }
                }
                .frame(
                    width: isSwapped ? 100 : geo.size.width,
                    height: isSwapped ? 130 : geo.size.height
                )
                .shadow(color: isSwapped ? .black.opacity(0.5) : .clear, radius: 5)
                .position(
                    x: isSwapped ? 72 : geo.size.width / 2,
                    y: isSwapped ? 92 : geo.size.height / 2
                )
                .zIndex(isSwapped ? 1 : 0)

                // 전면 카메라 (드래그 가능한 PIP)
                if !isSwapped {
                    ZStack(alignment: .topLeading) {
                        Color.clear
                            .frame(width: geo.size.width, height: geo.size.height)

                        DraggablePIP(
                            containerSize: geo.size,
                            pipWidth: 100,
                            pipHeight: 130,
                            padding: 12
                        ) {
                            if let frontLayer = cameraVM.frontPreviewLayer {
                                CameraPreviewView(previewLayer: frontLayer)
                            } else {
                                cameraPlaceholder(text: "전면", isMain: false)
                            }
                        }
                    }
                    .zIndex(1)
                } else {
                    // 스왑 시 전면이 메인
                    Group {
                        if let frontLayer = cameraVM.frontPreviewLayer {
                            CameraPreviewView(previewLayer: frontLayer)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            cameraPlaceholder(text: "전면", isMain: true)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .zIndex(0)
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.3), value: cameraVM.isCameraSwapped)

            Text(cameraVM.currentTimeText)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.customGray300)
                .padding(.top, 30)
                .padding(.bottom, 10)

            ZStack {
                Button {
                    cameraVM.capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 72, height: 72)
                        Circle()
                            .fill(.white)
                            .frame(width: 60, height: 60)
                    }
                }

                HStack {
                    Spacer()
                        .frame(width: 200)

                    Button {
                        cameraVM.isCameraSwapped.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.2))
                                .frame(width: 48, height: 48)
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .foregroundColor(.textWhite)
                                .font(.system(size: 20))
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
