import SwiftUI
import AVFoundation

@Observable
class AudioPlayer {
    private var audioPlayer: AVAudioPlayer?

    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0

    private var timer: Timer?

    func loadAudio(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            print("Loaded audio file with duration: \(duration)")
        } catch {
            print("Failed to load audio file: \(error)")
            duration = 0
        }
    }

    func play() {
        guard let player = audioPlayer else { return }

        player.currentTime = currentTime
        player.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        currentTime = 0
        isPlaying = false
        stopTimer()
    }

    func seek(to time: TimeInterval) {
        currentTime = min(max(time, 0), duration)
        audioPlayer?.currentTime = currentTime
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }

            self.currentTime = player.currentTime

            if !player.isPlaying && self.isPlaying {
                self.isPlaying = false
                self.stopTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stop()
    }
}

struct AudioPlayerView: View {
    let audioURL: URL
    @State private var audioPlayer = AudioPlayer()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(audioPlayer.duration == 0)

                VStack(alignment: .leading, spacing: 4) {
                    if audioPlayer.duration > 0 {
                        ProgressView(value: audioPlayer.currentTime / audioPlayer.duration)
                            .progressViewStyle(LinearProgressViewStyle())

                        HStack {
                            Text(formatTime(audioPlayer.currentTime))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(formatTime(audioPlayer.duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No audio available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            audioPlayer.loadAudio(from: audioURL)
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}