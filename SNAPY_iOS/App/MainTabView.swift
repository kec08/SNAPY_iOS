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
    @StateObject private var cameraVM = CameraViewModel()
    
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
            
            AlbumView()
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
        // 카메라 탭 선택 감지 → sheet 호출 후 이전 탭으로 복귀
        .onChange(of: selectedTab) {
            if selectedTab == 2 {
                showCamera = true
                selectedTab = 0
            }
        }
        .sheet(isPresented: $showCamera, onDismiss: {
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
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
