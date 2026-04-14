//
//  ContactSyncView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/14/26.
//

import SwiftUI
import Contacts

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
                VStack(alignment: .leading, spacing: 8) {
                    Text("친구들에게 SNAPY를 공유하고")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textWhite)
                    Text("함께 더 재미있게 즐겨보세요!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textWhite)
                }
                .padding(.top, 16)
                .padding(.horizontal, 24)

                Spacer()

                // MARK: 연락처 아이콘
                HStack {
                    Spacer()
                    Image("Contact_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                    Spacer()
                }

                Spacer()

                // MARK: 연락처 연동 버튼
                SnapyButton(title: "연락처 연동하기") {
                    requestContactAccess()
                }
                .padding(.bottom, 10)

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
    }

    /// 연락처 접근 권한 요청 → iOS 시스템 UI 가 자동으로 뜸
    /// 허용 후 연락처를 읽어서 서버 동기화
    private func requestContactAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                let phones = self.fetchAllPhoneNumbers(store: store)
                print("[ContactSync] 연락처 \(phones.count)개 번호 가져옴")
                Task {
                    do {
                        let contacts = try await FriendService.shared.syncContacts(phones: phones)
                        // 가입된 유저 handle 목록 저장 (친구 화면에서 "연락처에 있는 친구" 표시용)
                        let handles = contacts.map { $0.handle }
                        await MainActor.run {
                            UserDefaults.standard.set(handles, forKey: "contactSyncedHandles")
                        }
                        print("[ContactSync] 가입된 유저 \(contacts.count)명 동기화 완료")
                    } catch {
                        print("[ContactSync] 동기화 실패: \(error)")
                    }
                    await MainActor.run {
                        onDoneTap()
                    }
                }
            } else {
                print("[ContactSync] 연락처 권한 거부")
                Task { @MainActor in
                    onDoneTap()
                }
            }
        }
    }

    /// 연락처에서 전화번호 전체 추출
    private func fetchAllPhoneNumbers(store: CNContactStore) -> [String] {
        let keys = [CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var phones: [String] = []
        try? store.enumerateContacts(with: request) { contact, _ in
            for number in contact.phoneNumbers {
                let cleaned = number.value.stringValue
                    .replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "+82", with: "0")
                phones.append(cleaned)
            }
        }
        return phones
    }
}

#Preview {
    ContactSyncView(onDoneTap: {})
}
