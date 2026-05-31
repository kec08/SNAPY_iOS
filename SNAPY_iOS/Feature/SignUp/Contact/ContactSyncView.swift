//
//  ContactSyncView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/14/26.
//

import SwiftUI
import Contacts
import Kingfisher

struct ContactSyncView: View {
    var onDoneTap: () -> Void

    @State private var synced = false
    @State private var isSyncing = false
    @State private var contactUsers: [ContactUserData] = []
    @State private var requestedHandles: Set<String> = []

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            if !synced {
                syncPromptView
            } else {
                contactResultView
            }
        }
    }

    // MARK: - 동기화 전 화면

    private var syncPromptView: some View {
        VStack(alignment: .leading, spacing: 0) {
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

            HStack {
                Spacer()
                Image("Contact_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                Spacer()
            }

            Spacer()

            Text("연락처의 전화번호는 친구 추천 목적으로만 서버에 전송되며,\n제3자에게 공유되지 않습니다.")
                .font(.system(size: 12))
                .foregroundColor(.customGray300)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            SnapyButton(title: isSyncing ? "동기화 중..." : "연락처 연동하기", isEnabled: !isSyncing) {
                requestContactAccess()
            }
            .padding(.bottom, 10)

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

    // MARK: - 동기화 후 친구 추가 화면

    private var contactResultView: some View {
        VStack(alignment: .leading, spacing: 0) {
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

            if contactUsers.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Text("연락처에 SNAPY를 사용하는\n친구가 아직 없어요")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.customGray300)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("내 연락처에서 SNAPY를 사용하는 친구")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textWhite)
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(contactUsers) { user in
                            contactRow(user: user)
                        }
                    }
                }
            }

            Spacer()

            SnapyButton(title: "시작하기") {
                onDoneTap()
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - 연락처 유저 Row

    @ViewBuilder
    private func contactRow(user: ContactUserData) -> some View {
        let isRequested = requestedHandles.contains(user.handle)

        HStack(spacing: 12) {
            if let url = user.profileImageUrl, let imgUrl = URL(string: url) {
                KFImage(imgUrl)
                    .resizable()
                    .placeholder { Image("Profile_img").resizable().scaledToFill() }
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Image("Profile_img")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(user.username)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textWhite)
                Text("@\(user.handle)")
                    .font(.system(size: 13))
                    .foregroundColor(.customGray300)
            }

            Spacer()

            if isRequested {
                Text("요청됨")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.customGray300)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.customDarkGray)
                    .cornerRadius(6)
            } else {
                Button {
                    requestedHandles.insert(user.handle)
                    Task {
                        do {
                            try await FriendService.shared.sendRequest(handle: user.handle)
                        } catch {
                            // 409 등 이미 요청됨
                            requestedHandles.insert(user.handle)
                        }
                    }
                } label: {
                    Text("친구 추가")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.backgroundBlack)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.MainYellow)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    // MARK: - 연락처 동기화

    private func requestContactAccess() {
        isSyncing = true
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                let phones = fetchAllPhoneNumbers(store: store)
                print("[ContactSync] 연락처 \(phones.count)개 번호 가져옴")
                Task {
                    do {
                        let contacts = try await FriendService.shared.syncContacts(phones: phones)
                        let handles = contacts.map { $0.handle }
                        await MainActor.run {
                            UserDefaults.standard.set(handles, forKey: "contactSyncedHandles")
                            contactUsers = contacts
                            isSyncing = false
                            synced = true
                        }
                        print("[ContactSync] 가입된 유저 \(contacts.count)명 동기화 완료")
                    } catch {
                        print("[ContactSync] 동기화 실패: \(error)")
                        await MainActor.run {
                            isSyncing = false
                            synced = true
                        }
                    }
                }
            } else {
                print("[ContactSync] 연락처 권한 거부")
                Task { @MainActor in
                    isSyncing = false
                    onDoneTap()
                }
            }
        }
    }

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
