//
//  ProfileView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // 배너 + 프로필 + 정보 + 버튼
                        ProfileHeaderView(viewModel: viewModel)

                        Divider()
                            .background(Color(white: 0.3))
                            .padding(.horizontal, 16)

                        // 피드 그리드 (3열)
                        VStack(alignment: .leading, spacing: 12) {
                            // + 버튼 + 피드
                            HStack(spacing: 8) {
                                // 새 게시물 추가 버튼
                                VStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(white: 0.15))
                                            .frame(width: 60, height: 60)
                                        Image(systemName: "plus")
                                            .font(.system(size: 24))
                                            .foregroundColor(.customGray300)
                                    }
                                }
                                .padding(.leading, 16)

                                Spacer()
                            }
                            .padding(.bottom, 4)

                            ProfileFeedGrid(posts: viewModel.feedPosts)
                        }

                        Divider()
                            .background(Color(white: 0.3))
                            .padding(.horizontal, 16)

                        // 방명록
                        GuestbookSection()

                        Spacer()
                            .frame(height: 40)
                    }
                }
                .ignoresSafeArea(edges: .top)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // 설정 (나중에 구현)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundColor(.textWhite)
                    }
                    .buttonStyle(.glass)
                }
            }
            .sheet(isPresented: $viewModel.showEditProfile) {
                ProfileEditSheet(viewModel: viewModel)
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
