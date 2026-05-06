//
//  CommentSheetView.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/22/26.
//

import SwiftUI
import Kingfisher
import PhotosUI
import AVFoundation
import Combine

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

    @StateObject private var audioPlayer = AudioCommentPlayer()

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
        case .voice(let url, _):
            voiceComment(url: url)
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

    private func voiceComment(url: String) -> some View {
        HStack(spacing: 12) {
            Button {
                audioPlayer.togglePlayback(urlString: url)
            } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            }

            // 파형 (실제 오디오 데이터 기반, 재생 시 왼→오 채워짐)
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    let isActive = audioPlayer.isPlaying && Double(index) / 30.0 <= audioPlayer.progress
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isActive ? Color.black : Color.black.opacity(0.3))
                        .frame(width: 2.5, height: audioPlayer.waveformHeights[index])
                }
            }

            Text(formatDuration(audioPlayer.isPlaying ? audioPlayer.currentTime : audioPlayer.duration))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.MainYellow, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            audioPlayer.loadDuration(urlString: url)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - 음성 댓글 재생 플레이어

@MainActor
final class AudioCommentPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0  // 0.0 ~ 1.0
    @Published var currentTime: TimeInterval = 0
    @Published var waveformHeights: [CGFloat] = Array(repeating: 4, count: 30)

    private var player: AVAudioPlayer?
    private var downloadTask: URLSessionDataTask?
    private var progressTimer: AnyCancellable?
    private var cachedAudioData: Data?
    private let barCount = 30

    func loadDuration(urlString: String) {
        guard duration == 0, let url = URL(string: urlString), urlString.hasPrefix("http") else { return }
        // 다운로드해서 duration + 파형 동시에 분석
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data else { return }
            DispatchQueue.main.async {
                self.cachedAudioData = data
                if let tempPlayer = try? AVAudioPlayer(data: data) {
                    self.duration = tempPlayer.duration
                }
                self.extractWaveform(from: data)
            }
        }.resume()
    }

    /// 오디오 데이터에서 파형 추출 (AVAudioFile로 PCM 샘플 읽기)
    private func extractWaveform(from data: Data) {
        // 임시 파일에 저장 후 AVAudioFile로 읽기
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("waveform_\(UUID().uuidString).m4a")
        do {
            try data.write(to: tempURL)
            let file = try AVAudioFile(forReading: tempURL)
            guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false),
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length)) else {
                try? FileManager.default.removeItem(at: tempURL)
                return
            }
            try file.read(into: buffer)
            try? FileManager.default.removeItem(at: tempURL)

            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            let samplesPerBar = max(frameCount / barCount, 1)

            var heights: [CGFloat] = []
            for i in 0..<barCount {
                let start = i * samplesPerBar
                let end = min(start + samplesPerBar, frameCount)
                var sum: Float = 0
                for j in start..<end {
                    sum += abs(channelData[j])
                }
                let avg = sum / Float(end - start)
                heights.append(CGFloat(avg))
            }

            // 정규화 (4~28 범위로)
            let maxVal = heights.max() ?? 1
            if maxVal > 0 {
                waveformHeights = heights.map { max(4, ($0 / maxVal) * 28) }
            }
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    private func startProgressTimer() {
        progressTimer?.cancel()
        progress = 0
        currentTime = 0
        progressTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let player = self.player, player.isPlaying else { return }
                self.currentTime = player.currentTime
                self.progress = player.duration > 0 ? player.currentTime / player.duration : 0
            }
    }

    private func stopProgressTimer() {
        progressTimer?.cancel()
        progressTimer = nil
        progress = 0
        currentTime = 0
    }

    func togglePlayback(urlString: String) {
        if isPlaying {
            player?.stop()
            isPlaying = false
            stopProgressTimer()
            return
        }

        guard let url = URL(string: urlString) else { return }

        // 로컬 파일
        if url.isFileURL {
            playLocalFile(url)
            return
        }

        // 캐시된 데이터 있으면 바로 재생
        if let cached = cachedAudioData {
            playData(cached)
            return
        }

        // 리모트 URL → 다운로드 후 재생
        downloadTask?.cancel()
        downloadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data, error == nil else {
                print("[AudioPlayer] 다운로드 실패: \(error?.localizedDescription ?? "")")
                return
            }
            DispatchQueue.main.async {
                self?.cachedAudioData = data
                self?.playData(data)
            }
        }
        downloadTask?.resume()
    }

    private func playLocalFile(_ url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            duration = player?.duration ?? 0
            player?.play()
            isPlaying = true
            startProgressTimer()
        } catch {
            print("[AudioPlayer] 로컬 재생 실패: \(error)")
        }
    }

    private func playData(_ data: Data) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            duration = player?.duration ?? 0
            player?.play()
            isPlaying = true
            startProgressTimer()
        } catch {
            print("[AudioPlayer] 재생 실패: \(error)")
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.stopProgressTimer()
        }
    }
}

#Preview("댓글 있음") {
    CommentSheetView(albumId: 1, commentCount: .constant(0))
}
