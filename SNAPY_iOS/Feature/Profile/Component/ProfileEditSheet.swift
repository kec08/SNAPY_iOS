//
//  ProfileEditSheet.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/7/26.
//

import SwiftUI

struct ProfileEditSheet: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundBlack.ignoresSafeArea()

                VStack(spacing: 28) {
                    // 이름 수정
                    VStack(alignment: .leading, spacing: 8) {
                        Text("이름")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.customGray300)
                        TextField("이름을 입력해주세요", text: $viewModel.editUsername)
                            .font(.system(size: 17))
                            .foregroundColor(.textWhite)
                            .padding(.bottom, 8)
                        Rectangle()
                            .fill(viewModel.editUsername.isEmpty ? Color(white: 0.3) : Color.mainYellow)
                            .frame(height: 1.5)
                    }

                    // 사용자 ID 수정
                    VStack(alignment: .leading, spacing: 8) {
                        Text("사용자 ID")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.customGray300)
                        TextField("사용자 ID를 입력해주세요", text: $viewModel.editHandle)
                            .font(.system(size: 17))
                            .foregroundColor(.textWhite)
                            .textInputAutocapitalization(.never)
                            .padding(.bottom, 8)
                        Rectangle()
                            .fill(viewModel.editHandle.isEmpty ? Color(white: 0.3) : Color.mainYellow)
                            .frame(height: 1.5)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        viewModel.showEditProfile = false
                    }
                    .foregroundColor(.textWhite)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        viewModel.saveEdit()
                    }
                    .foregroundColor(.mainYellow)
                    .disabled(viewModel.editUsername.isEmpty || viewModel.editHandle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
