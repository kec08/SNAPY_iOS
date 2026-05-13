//
//  ShareCardViews.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 5/13/26.
//

import SwiftUI

// MARK: - 이미지 다운로드 유틸

func downloadImage(from urlString: String?) async -> UIImage? {
    guard let urlString, let url = URL(string: urlString),
          let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
    return UIImage(data: data)
}

// MARK: - 스토리 공유 카드

struct StoryShareCard: View {
    let profileImage: UIImage?
    let displayName: String
    let handle: String
    let backImage: UIImage?
    let frontImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if let img = profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(white: 0.3))
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("@\(handle)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()

                Image("SNAPY_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 14)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ZStack(alignment: .topLeading) {
                if let img = backImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 340)
                } else {
                    Color(white: 0.15)
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                        .frame(width: 340)
                }

                if let img = frontImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.3), lineWidth: 1))
                        .padding(.top, 12)
                        .padding(.leading, 12)
                }
            }
        }
        .frame(width: 340)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 피드 공유 카드

struct FeedShareCard: View {
    let profileImage: UIImage?
    let displayName: String
    let handle: String
    let date: String
    let backImage: UIImage?
    let frontImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if let img = profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(white: 0.3))
                        .frame(width: 36, height: 36)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("@\(handle)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()

                Text(date)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            ZStack(alignment: .topLeading) {
                if let img = backImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 340)
                } else {
                    Color(white: 0.15)
                        .aspectRatio(3.0/4.0, contentMode: .fit)
                        .frame(width: 340)
                }

                if let img = frontImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.3), lineWidth: 1))
                        .padding(.top, 12)
                        .padding(.leading, 12)
                }
            }

            Image("SNAPY_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 14)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .frame(width: 340)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 프로필 공유 카드

struct ProfileShareCard: View {
    let bannerImage: UIImage?
    let profileImage: UIImage?
    let username: String
    let handle: String
    let postCount: Int
    let friendCount: Int
    let streakCount: Int

    var body: some View {
        VStack(spacing: 0) {
            if let img = bannerImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 340, height: 120)
                    .clipped()
            } else {
                Color(white: 0.2)
                    .frame(width: 340, height: 120)
            }

            // 프로필 사진
            HStack {
                if let img = profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(white: 0.1), lineWidth: 3))
                } else {
                    Circle()
                        .fill(Color(white: 0.3))
                        .frame(width: 64, height: 64)
                        .overlay(Circle().stroke(Color(white: 0.1), lineWidth: 3))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, -20)

            // 이름 + 핸들
            VStack(alignment: .leading, spacing: 4) {
                Text(username)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("@\(handle)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 10)

            HStack(spacing: 0) {
                statItem(value: "\(postCount)", label: "게시물")
                statItem(value: "\(friendCount)", label: "친구")
                statItem(value: "\(streakCount)", label: "스트릭")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            HStack {
                Spacer()
                Image("SNAPY_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 14)
                Spacer()
            }
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 340)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("스토리 공유 카드") {
    ZStack {
        Color.black.ignoresSafeArea()
        StoryShareCard(
            profileImage: nil,
            displayName: "김은찬",
            handle: "silver_chan",
            backImage: nil,
            frontImage: nil
        )
    }
}

#Preview("피드 공유 카드") {
    ZStack {
        Color.black.ignoresSafeArea()
        FeedShareCard(
            profileImage: nil,
            displayName: "김은찬",
            handle: "silver_chan",
            date: "5월 13일",
            backImage: nil,
            frontImage: nil
        )
    }
}

#Preview("프로필 공유 카드") {
    ZStack {
        Color.black.ignoresSafeArea()
        ProfileShareCard(
            bannerImage: nil,
            profileImage: nil,
            username: "김은찬",
            handle: "silver_chan",
            postCount: 42,
            friendCount: 128,
            streakCount: 7
        )
    }
}

// MARK: - 이미지 렌더링 유틸

@MainActor
func renderShareImage<V: View>(_ view: V) -> UIImage? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
}

// MARK: - 공유 시트 (UIActivityViewController)

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
