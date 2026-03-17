//
//  LoginView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/17/26.
//

import SwiftUI
import Combine

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    // 현재 선택된 이미지 인덱스
    @State private var selectedIndex: Int = 0
    // ScrollViewReader에서 받은 proxy 저장 - 강제 이동에 사용
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    // 자동 스크롤 타이머
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    let images = ["Login_img1", "Login_img2", "Login_img3", "Login_img4", "Login_img5"]

    var body: some View {
        ZStack {
            Color.BackgroundBlack
                .ignoresSafeArea(.all)

            VStack(alignment: .leading, spacing: 0) {
                
                // Header
                HStack(spacing: 12) {
                    Image("Login_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 34)
                    Image("Login_TextLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 28)
                }
                .padding(.top, 34)
                .padding(.horizontal, 24)

                // 타이틀 텍스트
                VStack(alignment: .leading, spacing: 8) {
                    Text("로그인하여 친구들의 SNAPY를\n확인해보세요!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textWhite)
                        .lineSpacing(12)
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                Spacer()

                // 자동 슬라이드 이미지 캐러셀
                VStack(spacing: 16) {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 24) {
                                ForEach(0..<images.count, id: \.self) { index in
                                    ZStack {
                                        Image(images[index])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(
                                                width: index == selectedIndex ? 201 : 159,
                                                height: index == selectedIndex ? 300 : 240
                                            )
                                            .animation(.easeInOut(duration: 0.4), value: selectedIndex)
                                            .cornerRadius(20)

                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black)
                                            .opacity(index == selectedIndex ? 0 : 0.5)
                                            .frame(
                                                width: index == selectedIndex ? 201 : 159,
                                                height: index == selectedIndex ? 300 : 240
                                            )
                                            .animation(.easeInOut(duration: 0.4), value: selectedIndex)
                                    }
                                    .id(index)
                                }
                            }
                            .padding(.horizontal, 80)
                        }
                        .onAppear {
                            scrollProxy = proxy
                        }
                        // 스크롤 위치를 읽어서 selectedIndex 자동 계산
                        .onScrollGeometryChange(for: Int.self) { geometry in
                            let offset = geometry.contentOffset.x
                            let itemWidth: CGFloat = 201 + 24
                            let index = Int(round(offset / itemWidth))
                            return max(0, min(index, images.count - 1))
                        } action: { _, newIndex in
                            selectedIndex = newIndex
                        }
                    }

                    // 페이지 인디케이터
                    HStack(spacing: 8) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Capsule()
                                .fill(index == selectedIndex ? Color.textWhite : Color.customGray500)
                                .frame(width: index == selectedIndex ? 12 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: selectedIndex)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Spacer()
                    .frame(height: 90)
                
                AppleLoginButton(title: "Apple로 계속하기") {
                    withAnimation {
                        print("Apple로 계속하기 클릭")
                    }
                }
                .padding(.bottom, 24)

                // 하단 버튼
                SnapyButton(title: "SNAPY로 계속하기") {
                    withAnimation {
                        print("SNAPY로 계속하기 클릭")
                    }
                }
                .padding(.bottom, 24)
            }
        }
        // 3초마다 다음 이미지로 자동 전환
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                selectedIndex = (selectedIndex + 1) % images.count
                // 해당 카드가 화면 가운데에 오도록 강제 스크롤
                scrollProxy?.scrollTo(selectedIndex, anchor: .center)
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
