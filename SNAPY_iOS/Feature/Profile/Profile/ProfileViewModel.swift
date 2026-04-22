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

// 피드 게시물
struct FeedPost: Identifiable {
    let id: Int                 // albumId
    let thumbnailImage: String  // 에셋 또는 URL
    let photos: [PhotoData]     // 상세 사진들 (front + back)
    let date: String
}

// 이전 달 요약 (대표 사진 1장 + 월 표시)
struct PastMonthSummary: Identifiable {
    let id: Int                 // month 값
    let month: Int              // 1~12
    let year: Int
    let thumbnailUrl: String?   // 대표 썸네일
    var displayText: String { "\(month)월" }
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
    @Published var postCount: Int = 0
    @Published var friendCount: Int = 0
    @Published var streakCount: Int = 0
    @Published var mutualFriendsText: String = ""

    // 프로필/배너 이미지 URL (UserDefaults 에 저장 → 앱 재시작해도 유지)
    @Published var profileImageUrl: String? {
        didSet { UserDefaults.standard.set(profileImageUrl, forKey: "profileImageUrl") }
    }
    @Published var bannerImageUrl: String? {
        didSet { UserDefaults.standard.set(bannerImageUrl, forKey: "bannerImageUrl") }
    }

    // 프로필/배너 이미지 (디스크 캐시 → 즉시 표시, 로딩 없음)
    @Published var profileImage: UIImage? = nil
    @Published var bannerImage: UIImage? = nil

    // 디스크 캐시 경로
    private static let profileCachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("profile_image.jpg")
    private static let bannerCachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("banner_image.jpg")

    /// 이미지를 디스크에 저장
    private func saveImageToDisk(_ image: UIImage, path: URL) {
        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: path)
        }
    }

    /// 디스크에서 이미지 로드
    private static func loadImageFromDisk(_ path: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: path) else { return nil }
        return UIImage(data: data)
    }

    // 수정 모드
    @Published var showEditProfile = false
    @Published var editUsername: String = ""
    @Published var editHandle: String = ""

    // 이미지 피커
    @Published var profilePickerItem: PhotosPickerItem? = nil
    @Published var bannerPickerItem: PhotosPickerItem? = nil

    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    init() {
        profileImageUrl = UserDefaults.standard.string(forKey: "profileImageUrl")
        bannerImageUrl = UserDefaults.standard.string(forKey: "bannerImageUrl")
        profileImage = Self.loadImageFromDisk(Self.profileCachePath)
        bannerImage = Self.loadImageFromDisk(Self.bannerCachePath)
    }

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

    // 피드 (이번 달)
    @Published var feedPosts: [FeedPost] = []
    // 이전 달 요약 카드들
    @Published var pastMonths: [PastMonthSummary] = []

    // MARK: - 프로필 로드 (서버)

    func loadProfile() async {
        isLoading = true
        do {
            let profile = try await ProfileService.shared.fetchMyProfile()
            username = profile.username
            handle = profile.handle
            profileImageUrl = profile.profileImageUrl
            bannerImageUrl = profile.backgroundImageUrl
            // 자기 handle 저장 (추천 친구에서 자신 제외용)
            UserDefaults.standard.set(profile.handle, forKey: "myHandle")

            // 친구 수 서버에서 가져오기
            do {
                let friends = try await FriendService.shared.getFriends(handle: profile.handle)
                friendCount = friends.count
                print("[Profile] 친구 수: \(friends.count)")
            } catch {
                print("[Profile] 친구 목록 로드 실패: \(error)")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false

        // 피드 로드 (전체 앨범 → 상세 조회)
        await loadFeed()
    }

    // MARK: - 피드 로드 (이번 달 상세 + 이전 달 요약)

    func loadFeed() async {
        let now = Date()
        let cal = Calendar.current
        let currentMonth = cal.component(.month, from: now)
        let currentYear = cal.component(.year, from: now)

        // 이번 달 앨범 상세 로드
        await loadCurrentMonthFeed(month: currentMonth)

        // 이전 달 요약 카드 (calendar에서 월별 그룹핑)
        do {
            let allAlbums = try await AlbumService.shared.fetchCalendar()
            print("[ProfileVM] 전체 앨범 \(allAlbums.count)개 조회")

            // 이전 달별로 그룹핑 (이번 달 제외)
            var monthGroups: [String: [AlbumListItemData]] = [:]
            for album in allAlbums {
                let parts = album.albumDate.split(separator: "-")
                guard parts.count >= 2 else { continue }
                let yearMonth = "\(parts[0])-\(parts[1])"
                let albumMonth = Int(parts[1]) ?? 0
                let albumYear = Int(parts[0]) ?? 0
                if albumYear == currentYear && albumMonth == currentMonth { continue }
                monthGroups[yearMonth, default: []].append(album)
            }

            // 최신순 정렬
            let sortedKeys = monthGroups.keys.sorted(by: >)
            var summaries: [PastMonthSummary] = []
            for key in sortedKeys {
                let parts = key.split(separator: "-")
                guard parts.count == 2,
                      let year = Int(parts[0]),
                      let month = Int(parts[1]),
                      let albums = monthGroups[key],
                      let latest = albums.sorted(by: { $0.albumDate > $1.albumDate }).first else { continue }
                summaries.append(PastMonthSummary(
                    id: year * 100 + month,
                    month: month,
                    year: year,
                    thumbnailUrl: latest.thumbnailUrl
                ))
            }
            // TODO: 이전 달 데이터가 없을 때 확인용 임시 mock (나중에 제거)
            if summaries.isEmpty {
                let firstThumb = allAlbums.first?.thumbnailUrl
                summaries.append(PastMonthSummary(id: 202603, month: 3, year: 2026, thumbnailUrl: firstThumb))
            }
            pastMonths = summaries
            postCount = allAlbums.count
        } catch {
            print("[ProfileVM] 이전 달 로드 실패: \(error)")
        }
    }

    /// 특정 월의 앨범을 상세 조회하여 feedPosts에 세팅
    func loadCurrentMonthFeed(month: Int) async {
        do {
            let albums = try await AlbumService.shared.fetchAlbums(month: month)
            print("[ProfileVM] \(month)월 앨범 \(albums.count)개 조회")
            let sorted = albums.sorted { $0.albumDate > $1.albumDate }

            let posts: [FeedPost] = await withTaskGroup(of: FeedPost?.self) { group in
                for album in sorted {
                    group.addTask {
                        do {
                            let detail = try await AlbumService.shared.fetchAlbumAsDaily(albumId: album.albumId)
                            guard !detail.photos.isEmpty else { return nil }
                            let thumbnail = detail.photos.first?.backImageUrl ?? ""
                            return await FeedPost(
                                id: album.albumId,
                                thumbnailImage: thumbnail,
                                photos: detail.photos,
                                date: Self.formatAlbumDate(album.albumDate)
                            )
                        } catch {
                            print("[ProfileVM] 앨범 상세 실패 (id=\(album.albumId)): \(error)")
                            return nil
                        }
                    }
                }
                var results: [FeedPost] = []
                for await post in group {
                    if let post { results.append(post) }
                }
                return results.sorted { $0.date > $1.date }
            }
            feedPosts = posts
            print("[ProfileVM] \(month)월 피드 \(posts.count)개 로드 완료")
        } catch {
            print("[ProfileVM] \(month)월 피드 로드 실패: \(error)")
        }
    }

    /// 이전 달 다시보기 → 해당 월 피드 로드
    func loadMonthFeed(month: Int) async -> [FeedPost] {
        do {
            let albums = try await AlbumService.shared.fetchAlbums(month: month)
            let sorted = albums.sorted { $0.albumDate > $1.albumDate }

            return await withTaskGroup(of: FeedPost?.self) { group in
                for album in sorted {
                    group.addTask {
                        do {
                            let detail = try await AlbumService.shared.fetchAlbumAsDaily(albumId: album.albumId)
                            guard !detail.photos.isEmpty else { return nil }
                            let thumbnail = detail.photos.first?.backImageUrl ?? ""
                            return await FeedPost(
                                id: album.albumId,
                                thumbnailImage: thumbnail,
                                photos: detail.photos,
                                date: Self.formatAlbumDate(album.albumDate)
                            )
                        } catch { return nil }
                    }
                }
                var results: [FeedPost] = []
                for await post in group {
                    if let post { results.append(post) }
                }
                return results.sorted { $0.date > $1.date }
            }
        } catch {
            return []
        }
    }

    /// "2026-04-20" → "2026.04.20"
    private static func formatAlbumDate(_ dateStr: String) -> String {
        dateStr.replacingOccurrences(of: "-", with: ".")
    }

    // MARK: - 수정 모드

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

    // MARK: - 프로필 이미지 변경 (피커 → 서버 업로드)

    func loadProfileImage() async {
        guard let item = profilePickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            profileImage = image
            saveImageToDisk(image, path: Self.profileCachePath)
            do {
                let url = try await ProfileService.shared.updateProfileImage(image)
                profileImageUrl = url
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - 배너 이미지 변경 (피커 → 서버 업로드)

    func loadBannerImage() async {
        guard let item = bannerPickerItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            bannerImage = image
            saveImageToDisk(image, path: Self.bannerCachePath)
            do {
                let url = try await ProfileService.shared.updateBackgroundImage(image)
                bannerImageUrl = url
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
