
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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 카메라 뷰를 항상 유지하여 세션 연결이 끊기지 않도록 함
            cameraContentView
                .opacity(cameraVM.showPreview || cameraVM.showPostConfirm ? 0 : 1)
                .allowsHitTesting(!cameraVM.showPreview && !cameraVM.showPostConfirm)

            if cameraVM.showPostConfirm {
                PostConfirmView()
                    .environmentObject(cameraVM)
            } else if cameraVM.showPreview {
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
            Text("추억이 남을 사진을 찍어보세요!")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 50)

            Spacer()

            // 멀티캠 화면
            ZStack {
                // 메인 카메라
                if let backLayer = cameraVM.backPreviewLayer {
                    // 후면 카메라
                    CameraPreviewView(previewLayer: backLayer)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.1))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .font(.system(size: 48))
                                Text("후면 카메라")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        )
                }

                // 작은 카메라
                VStack {
                    HStack {
                        ZStack {
                            if let frontLayer = cameraVM.frontPreviewLayer {
                                // 전면 카메라
                                CameraPreviewView(previewLayer: frontLayer)
                                    .frame(width: 120, height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(white: 0.2))
                                    .frame(width: 100, height: 130)
                                    .overlay(
                                        VStack(spacing: 4) {
                                            Image(systemName: "camera.fill")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 18))
                                            Text("전면")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 11))
                                        }
                                    )
                            }
                        }
                        .shadow(color: .black.opacity(0.5), radius: 5)
                        .padding(12)

                        Spacer()
                    }
                    Spacer()
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            .padding(.horizontal, 16)

            // Photo count
            Text(cameraVM.photoCountText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.top, 30)
            
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
                .disabled(cameraVM.capturedPhotos.count >= cameraVM.maxPhotos)

                HStack {
                    Spacer()
                        .frame(width: 200)
                    
                    Button {
                        // TODO: 카메라 전환
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
