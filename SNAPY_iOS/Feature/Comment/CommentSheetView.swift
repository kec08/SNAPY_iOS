//
//  CommentSheetView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/22/26.
//

import SwiftUI
import Kingfisher
import PhotosUI

struct CommentSheetView: View {
    let albumId: Int
    @Binding var commentCount: Int
    @State private var comments: [Comment] = []
    @State private var showEmojiBar = false
    @State private var showVoiceRecorder = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isLoading = false
    @State private var nextCursor: Int? = nil
    @State private var hasMore = true
    @State private var deleteTarget: Comment? = nil
    @State private var showDeleteAlert = false

    private let emojis = ["💕", "🔥", "🤩", "😍", "😢", "😡", "💀"]
    private let myHandle = UserDefaults.standard.string(forKey: "myHandle") ?? ""

    var body: some View {
        ZStack {
            Color.backgroundBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // 드래그 인디케이터
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.customGray300)
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)

                // 타이틀
                Text("댓글")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textWhite)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                // 댓글 목록 or 빈 상태
                if isLoading && comments.isEmpty {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if comments.isEmpty {
                    emptyView
                } else {
                    commentListView
                }

                Spacer()

                // 이모지 바
                if showEmojiBar {
                    emojiBarView
                }

                // 하단 입력 바
                inputBar
            }
        }
        .sheet(isPresented: $showVoiceRecorder) {
            VoiceRecorderSheet { recordedURL in
                Task { await uploadAudio(url: recordedURL) }
            }
            .presentationDetents([.fraction(0.55)])
            .presentationDragIndicator(.hidden)
        }
        .onAppear {
            Task { await loadComments() }
        }
        .alert("댓글 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {
                deleteTarget = nil
            }
            Button("삭제", role: .destructive) {
                if let target = deleteTarget {
                    Task { await deleteComment(target) }
                    deleteTarget = nil
                }
            }
        } message: {
            Text("이 댓글을 삭제하시겠습니까?")
        }
    }

    // MARK: - 빈 상태

    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("텅 비었네요...")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textWhite)
            Text("사용자가 당신의 댓글을 기다리고 있어요!")
                .font(.system(size: 14))
                .foregroundColor(.customGray300)
            Spacer()
        }
    }

    // MARK: - 댓글 목록

    private var commentListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(comments) { comment in
                    CommentRow(
                        comment: comment,
                        isMine: comment.handle == myHandle,
                        onDelete: {
                            deleteTarget = comment
                            showDeleteAlert = true
                        }
                    )
                }

                // 더보기
                if hasMore && !isLoading {
                    Button {
                        Task { await loadMoreComments() }
                    } label: {
                        Text("더보기")
                            .font(.system(size: 14))
                            .foregroundColor(.customGray300)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }

                if isLoading && !comments.isEmpty {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    // MARK: - 이모지 바

    private var emojiBarView: some View {
        HStack(spacing: 16) {
            ForEach(emojis, id: \.self) { emoji in
                Button {
                    Task { await uploadEmoji(emoji) }
                    showEmojiBar = false
                } label: {
                    Text(emoji)
                        .font(.system(size: 32))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - 하단 출력 바

    private var inputBar: some View {
        HStack(spacing: 0) {
            // 이미지 버튼
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.customDarkGray, in: Circle())
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task { await uploadPickedImage(item: newItem) }
                selectedPhotoItem = nil
            }

            Spacer()

            // 음성 녹음 버튼
            Button {
                showVoiceRecorder = true
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.red, in: Circle())
            }

            Spacer()

            // 이모지 버튼 / 닫기 버튼
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showEmojiBar.toggle()
                }
            } label: {
                if showEmojiBar {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 52, height: 52)
                        .background(Color.customDarkGray, in: Circle())
                } else {
                    Text("😊")
                        .font(.system(size: 28))
                        .frame(width: 52, height: 52)
                        .background(Color.customDarkGray, in: Circle())
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 30)
        .padding(.top, 10)
    }

    // MARK: - 서버 통신

    private func loadComments() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await CommentService.shared.fetchComments(albumId: albumId)
            comments = result.content.map { Comment(from: $0) }
            commentCount = comments.count
            nextCursor = result.nextCursor
            hasMore = result.hasNext
        } catch {
            print("[CommentSheet] 댓글 로드 실패: \(error)")
        }
    }

    private func loadMoreComments() async {
        guard hasMore, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await CommentService.shared.fetchComments(albumId: albumId, cursor: nextCursor)
            comments.append(contentsOf: result.content.map { Comment(from: $0) })
            nextCursor = result.nextCursor
            hasMore = result.hasNext
        } catch {
            print("[CommentSheet] 댓글 더보기 실패: \(error)")
        }
    }

    private func uploadPickedImage(item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            print("[CommentSheet] 이미지 로드 실패")
            return
        }
        // 낙관적 추가 (로컬 이미지를 임시 URL로)
        let temp = Comment(profileImageUrl: nil, handle: myHandle, type: .image(url: ""))
        comments.append(temp)
        commentCount = comments.count
        do {
            _ = try await CommentService.shared.uploadImage(albumId: albumId, image: image)
            await loadComments()
        } catch {
            print("[CommentSheet] 이미지 댓글 실패: \(error)")
            comments.removeAll { $0.id == temp.id }
            commentCount = comments.count
        }
    }

    private func uploadEmoji(_ emoji: String) async {
        // 낙관적 추가
        let temp = Comment(profileImageUrl: nil, handle: myHandle, type: .emoji(emoji))
        comments.append(temp)
        commentCount = comments.count
        do {
            _ = try await CommentService.shared.uploadEmoji(albumId: albumId, emoji: emoji)
            await loadComments()
        } catch {
            print("[CommentSheet] 이모지 댓글 실패: \(error)")
            comments.removeAll { $0.id == temp.id }
            commentCount = comments.count
        }
    }

    private func uploadAudio(url: URL) async {
        let temp = Comment(profileImageUrl: nil, handle: myHandle, type: .voice(url: url.absoluteString, duration: 4))
        comments.append(temp)
        commentCount = comments.count
        do {
            _ = try await CommentService.shared.uploadAudio(albumId: albumId, audioURL: url)
            await loadComments()
        } catch {
            print("[CommentSheet] 음성 댓글 실패: \(error)")
            comments.removeAll { $0.id == temp.id }
            commentCount = comments.count
        }
    }

    private func deleteComment(_ comment: Comment) async {
        comments.removeAll { $0.id == comment.id }
        commentCount = comments.count
        do {
            try await CommentService.shared.deleteComment(commentId: comment.id)
        } catch {
            print("[CommentSheet] 댓글 삭제 실패: \(error)")
            await loadComments()
        }
    }
}

// MARK: - 댓글 행

struct CommentRow: View {
    let comment: Comment
    var isMine: Bool = false
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 프로필
            profileImage
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text(comment.handle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textWhite)

                commentContent
            }

            Spacer()

            if isMine {
                Button {
                    onDelete?()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.customGray300)
                }
            }
        }
    }

    @ViewBuilder
    private var profileImage: some View {
        if let url = comment.profileImageUrl, let imgUrl = URL(string: url) {
            KFImage(imgUrl)
                .resizable()
                .placeholder { Color.customDarkGray }
                .scaledToFill()
        } else {
            Image("Profile_img")
                .resizable()
                .scaledToFill()
        }
    }

    @ViewBuilder
    private var commentContent: some View {
        switch comment.type {
        case .image(let url):
            imageComment(url: url)
        case .voice(_, let duration):
            voiceComment(duration: duration)
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: 48))
        }
    }

    // MARK: - 이미지 댓글

    @ViewBuilder
    private func imageComment(url: String) -> some View {
        if url.isImageURL, let imgUrl = URL(string: url) {
            KFImage(imgUrl)
                .resizable()
                .placeholder { Color.customDarkGray }
                .scaledToFill()
                .frame(width: 200, height: 160)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            Image(url)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 160)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - 음성 댓글

    private func voiceComment(duration: TimeInterval) -> some View {
        HStack(spacing: 12) {
            Button {
                // 재생 (추후 구현)
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            }

            // 파형
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 2.5, height: CGFloat.random(in: 8...28))
                }
            }

            Text(formatDuration(duration))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.MainYellow, in: RoundedRectangle(cornerRadius: 16))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview("댓글 있음") {
    CommentSheetView(albumId: 1, commentCount: .constant(0))
}
