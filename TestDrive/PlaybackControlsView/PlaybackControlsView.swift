import SwiftUI
import SwiftData

/// Displays playback controls for the currently playing episode.
struct PlaybackControlsView: View {
    private let playbackManager: PlaybackManager

    // MARK: - Initializer

    /// Creates a new PlaybackControlsView.
    /// - Parameter playbackManager: The playback manager controlling audio.
    init(playbackManager: PlaybackManager) {
        self.playbackManager = playbackManager
    }

    // MARK: - Body

    var body: some View {
        if playbackManager.currentEpisode != nil {
            VStack(spacing: 0) {
                Divider()

                VStack(spacing: 8) {
                    progressBar

                    HStack(spacing: 16) {
                        episodeInfo

                        Spacer()

                        playbackButtons
                    }
                }
                .padding()
                .background(.regularMaterial)
            }
        }
    }

    // MARK: - Private Views

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 3)

                Rectangle()
                    .fill(.blue)
                    .frame(width: geometry.size.width * progress, height: 3)
            }
        }
        .frame(height: 3)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let newProgress = value.location.x / UIScreen.main.bounds.width
                    let newTime = max(0, min(playbackManager.duration, newProgress * playbackManager.duration))
                    playbackManager.seek(to: newTime)
                }
        )
    }

    private var episodeInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let episode = playbackManager.currentEpisode {
                Text(episode.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("\(formattedTime(playbackManager.currentTime)) / \(formattedTime(playbackManager.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var playbackButtons: some View {
        HStack(spacing: 20) {
            Button {
                playbackManager.skipBackward()
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Button {
                playbackManager.togglePlayPause()
            } label: {
                Image(systemName: playbackManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.largeTitle)
            }
            .buttonStyle(.plain)

            Button {
                playbackManager.skipForward()
            } label: {
                Image(systemName: "goforward.15")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Private Helpers

    /// Calculates the current playback progress as a percentage.
    private var progress: Double {
        guard playbackManager.duration > 0 else { return 0 }
        return playbackManager.currentTime / playbackManager.duration
    }

    /// Formats a time interval for display.
    /// - Parameter time: Time in seconds.
    /// - Returns: Formatted time string (e.g., "1:23:45" or "12:34").
    private func formattedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DownloadedEpisode.self, configurations: config)
    let context = container.mainContext

    let playbackManager = PlaybackManager(modelContext: context)

    // Create a mock downloaded episode
    let episode = DownloadedEpisode(
        episodeID: 1,
        title: "Episode 612: Very Long Episode Title That Should Truncate",
        episodeDescription: "Description",
        duration: 7265,
        localFilePath: "/path/to/file.mp3",
        publishDate: Date()
    )

    playbackManager.currentEpisode = episode
    playbackManager.isPlaying = true
    playbackManager.currentTime = 1825
    playbackManager.duration = 7265

    return PlaybackControlsView(playbackManager: playbackManager)
        .modelContainer(container)
}
