//
//  ProfileViewModel.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 3/18/26.
//

import Foundation
import SwiftUI
import PhotosUI
import Combine

// 피드 목데이터
struct FeedPost: Identifiable {
    let id = UUID()
    let thumbnailImage: String  // 에셋 이미지 이름
    let images: [String]        // 상세 이미지들 (1~5장)
    let date: String
}

// 방명록 엔트리
struct GuestbookEntry: Identifiable {
    let id = UUID()
    let assetName: String?            // 사진 (목)
    let image: UIImage?               // 사진 (사용자 추가)
    let authorProfileAsset: String?   // 작성자 프사 (에셋)
    let authorProfileImage: UIImage?  // 작성자 프사 (UIImage)

    init(assetName: String, authorProfileAsset: String = "Profile_img") {
        self.assetName = assetName
        self.image = nil
        self.authorProfileAsset = authorProfileAsset
        self.authorProfileImage = nil
    }

    init(image: UIImage, authorProfileImage: UIImage? = nil, authorProfileAsset: String? = "Profile_img") {
        self.assetName = nil
        self.image = image
        self.authorProfileAsset = authorProfileImage == nil ? authorProfileAsset : nil
        self.authorProfileImage = authorProfileImage
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    // 프로필 정보
    @Published var username: String = "김은찬"
    @Published var handle: String = "silver_c.ld"
    @Published var postCount: Int = 5
    @Published var friendCount: Int = 13
    @Published var streakCount: Int = 2
    @Published var mutualFriendsText: String = "zhvcx_flii, kimikhnа0816님 외 32명 친구 중 입니다"

    // 프로필/배너 이미지
    @Published var profileImage: UIImage? = nil
    @Published var bannerImage: UIImage? = nil

    // 수정 모드
    @Published var showEditProfile = false
    @Published var editUsername: String = ""
    @Published var editHandle: String = ""

    // 이미지 피커
    @Published var profilePickerItem: PhotosPickerItem? = nil
    @Published var bannerPickerItem: PhotosPickerItem? = nil

    // 방명록 목데이터
    @Published var guestbookEntries: [GuestbookEntry] = [
        GuestbookEntry(assetName: "Mock_img1"),
        GuestbookEntry(assetName: "Mock_img2"),
        GuestbookEntry(assetName: "Mock_img3"),
        GuestbookEntry(assetName: "Mock_img4"),
        GuestbookEntry(assetName: "Mock_img5"),
        GuestbookEntry(assetName: "Mock_img6"),
    ]

    // 방명록 추가 (사용자가 본인 방명록을 임시로 남길 수 있도록)
    func addGuestbookImage(_ image: UIImage) {
        guestbookEntries.insert(GuestbookEntry(image: image), at: 0)
    }

    // 피드 목데이터
    @Published var feedPosts: [FeedPost] = [
        FeedPost(thumbnailImage: "Mock_img1", images: ["Mock_img2", "Mock_img3"], date: "2026.04.01"),
        FeedPost(thumbnailImage: "Mock_img2", images: ["Mock_img4", "Mock_img5"], date: "2026.03.28"),
        FeedPost(thumbnailImage: "Mock_img3", images: ["Mock_img2", "Mock_img1", "Banner_img"], date: "2026.03.25"),
        FeedPost(thumbnailImage: "Mock_img4", images: ["Mock_img3", "Mock_img4"], date: "2026.03.20"),
    ]

    func startEdit() {
        editUsername = username
        editHandle = handle
        showEditProfile = true
    }

    func saveEdit() {
        username = editUsername
        handle = editHandle
        showEditProfile = false
    }

    func loadProfileImage() async {
        guard let item = profilePickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            profileImage = image
        }
    }

    func loadBannerImage() async {
        guard let item = bannerPickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            bannerImage = image
        }
    }
}
