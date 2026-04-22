//
//  VoiceRecorderSheet.swift
//  SNAPY_iOS
//
//  Created by 김은찬 on 4/22/26.
//

import SwiftUI
import AVFoundation
import Combine

struct VoiceRecorderSheet: View {
    var onSend: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = VoiceRecorderVM()

    var body: some View {
        ZStack {
            Color.MainYellow.ignoresSafeArea()

            VStack(spacing: 0) {
                // 드래그 인디케이터
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)

                Text("음성 댓글")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 14)

                Spacer()

                // 캐릭터 이미지
                Image("Listen_img")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 70)

                // 타이머
                Text(recorder.timerText)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .monospacedDigit()
                    .padding(.top, 8)

                // 파형
                waveformView
                    .frame(height: 120)
                    .padding(.horizontal, 12)
                    .padding(.top, 16)

                Spacer()

                // 하단 버튼
                if recorder.state == .recorded {
                    // 녹음 완료 → 다시녹음 / 재생 / 전송
                    recordedButtons
                } else {
                    // 녹음 중 → 정지 버튼
                    recordingButton
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            recorder.startRecording()
        }
        .onDisappear {
            recorder.cleanup()
        }
    }

    // MARK: - 파형

    @ViewBuilder
    private var waveformView: some View {
        if recorder.state == .recording {
            // 녹음 중: 오른쪽에서 왼쪽으로 (새 막대가 오른쪽에 쌓이고 왼쪽으로 밀림)
            recordingWaveform
        } else {
            // 녹음 완료: 전체 파형 + 재생 진행 표시 (왼쪽→오른쪽)
            playbackWaveform
        }
    }

    /// 녹음 중 — 오른쪽→왼쪽 (새 막대가 오른쪽에서 나와 왼쪽으로 밀림)
    private var recordingWaveform: some View {
        GeometryReader { geo in
            let barWidth: CGFloat = 3.5
            let spacing: CGFloat = 2
            let maxBars = Int(geo.size.width / (barWidth + spacing))
            let visibleSamples = recorder.waveformSamples.suffix(maxBars)

            HStack(alignment: .center, spacing: spacing) {
                if visibleSamples.count < maxBars {
                    Spacer(minLength: 0)
                }
                ForEach(Array(visibleSamples.enumerated()), id: \.offset) { _, sample in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.7))
                        .frame(width: barWidth, height: max(2, CGFloat(sample) * 110))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .animation(.easeOut(duration: 0.08), value: recorder.waveformSamples.count)
    }

    /// 재생 중 — 왼쪽→오른쪽 스크롤 (녹음과 같은 속도로 스크롤)
    private var playbackWaveform: some View {
        GeometryReader { geo in
            let barWidth: CGFloat = 3.5
            let spacing: CGFloat = 2
            let totalWidth = CGFloat(recorder.waveformSamples.count) * (barWidth + spacing)
            let progress = recorder.playbackProgress
            // 현재 재생 위치가 화면 오른쪽 끝에 오도록 오프셋 계산
            let currentX = totalWidth * progress
            let offset = min(0, geo.size.width - currentX)

            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(recorder.waveformSamples.enumerated()), id: \.offset) { index, sample in
                    let barX = CGFloat(index) * (barWidth + spacing)
                    let isPlayed = barX <= currentX
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isPlayed
                              ? Color.black.opacity(0.85)
                              : Color.black.opacity(0.25))
                        .frame(width: barWidth, height: max(2, CGFloat(sample) * 110))
                }
            }
            .offset(x: offset)
            .animation(.linear(duration: 0.05), value: progress)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            .clipped()
        }
    }

    // MARK: - 녹음 중 버튼

    private var recordingButton: some View {
        Button {
            recorder.stopRecording()
        } label: {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 28, height: 28)
                .padding(18)
                .background(
                    Circle()
                        .fill(Color.red)
                )
        }
    }

    // MARK: - 녹음 완료 버튼들

    private var recordedButtons: some View {
        HStack(spacing: 40) {
            // 다시 녹음
            Button {
                recorder.resetAndRecord()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.orange, in: Circle())
            }

            // 재생
            Button {
                recorder.togglePlayback()
            } label: {
                Image(systemName: recorder.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(Color.red, in: Circle())
            }

            // 전송
            Button {
                if let url = recorder.recordedURL {
                    onSend(url)
                    dismiss()
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.orange, in: Circle())
            }
        }
    }
}

// MARK: - ViewModel

enum RecorderState {
    case idle, recording, recorded
}

@MainActor
final class VoiceRecorderVM: ObservableObject {
    @Published var state: RecorderState = .idle
    @Published var timerText: String = "00:00:00"
    @Published var waveformSamples: [Float] = []
    @Published var isPlaying = false
    @Published var playbackProgress: CGFloat = 0

    private var lastSmoothedValue: Float = 0
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var playbackTimer: Timer?
    private var startTime: Date?
    private(set) var recordedURL: URL?

    private var fileURL: URL {
        let dir = FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("snapy_voice_\(UUID().uuidString).m4a")
    }

    func startRecording() {
        // 마이크 권한 확인 후 녹음 시작
        AVAudioApplication.requestRecordPermission { granted in
            Task { @MainActor in
                guard granted else {
                    print("[VoiceRecorder] 마이크 권한 거부됨")
                    return
                }
                self.beginRecording()
            }
        }
    }

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("[VoiceRecorder] 세션 설정 실패: \(error)")
            return
        }

        let url = fileURL
        recordedURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            state = .recording
            startTime = Date()
            startTimer()
        } catch {
            print("[VoiceRecorder] 녹음 시작 실패: \(error)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        stopTimer()
        state = .recorded
    }

    func resetAndRecord() {
        cleanup()
        waveformSamples = []
        timerText = "00:00:00"
        startRecording()
    }

    func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            stopPlaybackTimer()
            isPlaying = false
            return
        }
        guard let url = recordedURL else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
            playbackProgress = 0
            startPlaybackTimer()
        } catch {
            print("[VoiceRecorder] 재생 실패: \(error)")
        }
    }

    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.audioPlayer else { return }
                if player.isPlaying {
                    self.playbackProgress = CGFloat(player.currentTime / player.duration)
                    // 재생 시간 표시
                    let elapsed = player.currentTime
                    let mins = Int(elapsed) / 60
                    let secs = Int(elapsed) % 60
                    let hundredths = Int((elapsed.truncatingRemainder(dividingBy: 1)) * 100)
                    self.timerText = String(format: "%02d:%02d:%02d", mins, secs, hundredths)
                } else {
                    self.playbackProgress = 1.0
                    self.isPlaying = false
                    self.stopPlaybackTimer()
                }
            }
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    func cleanup() {
        audioRecorder?.stop()
        audioPlayer?.stop()
        stopTimer()
        stopPlaybackTimer()
        isPlaying = false
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.state == .recording else { return }
                self.updateTimer()
                self.updateWaveform()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateTimer() {
        guard let start = startTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        let mins = Int(elapsed) / 60
        let secs = Int(elapsed) % 60
        let hundredths = Int((elapsed.truncatingRemainder(dividingBy: 1)) * 100)
        timerText = String(format: "%02d:%02d:%02d", mins, secs, hundredths)
    }

    private func updateWaveform() {
        audioRecorder?.updateMeters()
        let power = audioRecorder?.averagePower(forChannel: 0) ?? -60
        // -60~0 dB → 0~1 로 변환, 지수 스케일로 작은 소리도 잘 보이게
        let linear = max(0, (power + 60) / 60)
        let scaled = pow(linear, 0.6)  // 0.6 지수로 작은 소리 증폭
        // 스무딩: 이전 값과 블렌드 (떨림 제거)
        let smoothed = lastSmoothedValue * 0.3 + scaled * 0.7
        lastSmoothedValue = smoothed
        waveformSamples.append(smoothed)
    }
}

#Preview {
    VoiceRecorderSheet(onSend: { _ in })
}
