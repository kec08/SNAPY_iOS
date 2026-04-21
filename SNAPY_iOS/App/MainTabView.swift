//
//  MainTabView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showCamera: Bool = false
    @State private var toastMessage: String?
    @StateObject private var cameraVM = CameraViewModel()
    @ObservedObject private var photoStore = PhotoStore.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image("Home_icon")
                        .renderingMode(.template)
                    Text("홈")
                }
                .tag(0)

            FriendView()
                .tabItem {
                    Image("Friend_icon")
                        .renderingMode(.template)
                    Text("친구")
                }
                .tag(1)

            // 카메라 호출
            Color.clear
                .tabItem {
                    Image("Camera_icon")
                }
                .tag(2)

            NavigationStack {
                AlbumView(onOpenCamera: { tryOpenCamera() })
            }
            .tabItem {
                Image("Album_icon")
                    .renderingMode(.template)
                Text("앨범")
            }
            .tag(3)

            ProfileView()
                .tabItem {
                    Image("Profile_icon")
                        .renderingMode(.template)
                    Text("프로필")
                }
                .tag(4)
        }
        .tint(.white)
        .overlay(alignment: .bottom) {
            if let message = toastMessage {
                toastView(message: message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toastMessage)
        .onChange(of: selectedTab) {
            if selectedTab == 2 {
                tryOpenCamera()
                selectedTab = 0
            }
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            cameraVM.resetCamera()
        }) {
            CameraView()
                .environmentObject(cameraVM)
        }
        .onChange(of: cameraVM.shouldDismiss) {
            if cameraVM.shouldDismiss {
                showCamera = false
            }
        }
    }

    private func tryOpenCamera() {
        Task {
            // 최신 todayAlbum을 서버에서 가져온 뒤 슬롯 체크
            await photoStore.loadToday()
            if let message = photoStore.cannotTakePhotoMessage() {
                showToast(message)
            } else {
                showCamera = true
            }
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            toastMessage = nil
        }
    }

    @ViewBuilder
    private func toastView(message: String) -> some View {
        Text(message)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
