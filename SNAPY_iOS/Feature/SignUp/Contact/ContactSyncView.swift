//
//  ContactSyncView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/14/26.
//

import SwiftUI
import ContactsUI

struct ContactSyncView: View {
    var onDoneTap: () -> Void

    @State private var showContactPicker = false

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // MARK: 헤더
                HStack(spacing: 12) {
                    Image("Login_Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)

                    Text("SNAPY")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.textWhite)
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)

                // 설명 텍스트
                VStack(alignment: .leading, spacing: 6) {
                    Text("친구들에게 SNAPY를 공유하고")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.customGray300)
                    Text("함께 더 재미있게 즐겨보세요!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.customGray300)
                }
                .padding(.top, 16)
                .padding(.horizontal, 24)

                Spacer()

                // MARK: 연락처 아이콘
                HStack {
                    Spacer()
                    Image("contact_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                    Spacer()
                }

                Spacer()

                // MARK: 연락처 연동 버튼
                Button {
                    showContactPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image("Login_Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)

                        Text("연락처 연동하기")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.backgroundBlack)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.textWhite)
                    .cornerRadius(28)
                }
                .padding(.horizontal, 24)

                // 건너뛰기
                Button {
                    onDoneTap()
                } label: {
                    Text("건너뛰기")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.customGray300)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                }
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView { phoneNumbers in
                // 선택된 연락처 전화번호로 서버에 동기화
                Task {
                    do {
                        try await syncContacts(phones: phoneNumbers)
                    } catch {
                        print("[ContactSync] 동기화 실패: \(error)")
                    }
                }
                onDoneTap()
            }
        }
    }

    private func syncContacts(phones: [String]) async throws {
        // POST /api/contacts/sync 호출
        // 추후 FriendService 에 연결
        print("[ContactSync] 동기화 요청 - \(phones.count)개 번호")
    }
}

// MARK: - 연락처 피커 (UIKit 래핑)

struct ContactPickerView: UIViewControllerRepresentable {
    let onPicked: ([String]) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let onPicked: ([String]) -> Void

        init(onPicked: @escaping ([String]) -> Void) {
            self.onPicked = onPicked
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            let phones = contacts.compactMap { contact in
                contact.phoneNumbers.first?.value.stringValue
                    .replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "+82", with: "0")
            }
            onPicked(phones)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onPicked([])
        }
    }
}

#Preview {
    ContactSyncView(onDoneTap: {})
}
