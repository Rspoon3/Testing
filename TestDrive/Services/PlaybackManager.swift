import Foundation
import AVFoundation
import SwiftData

/// Manages audio playback for podcast episodes with background support.
@Observable
final class PlaybackManager {
    /// The currently playing episode.
    var currentEpisode: DownloadedEpisode?

    /// Whether audio is currently playing.
    var isPlaying = false

    /// Current playback time in seconds.
    var currentTime: TimeInterval = 0

    /// Total duration of current episode in seconds.
    var duration: TimeInterval = 0

    private var player: AVPlayer?
    private var timeObserver: Any?
    private let modelContext: ModelContext

    // MARK: - Initializer

    /// Creates a new PlaybackManager instance.
    /// - Parameter modelContext: The SwiftData model context for persistence.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupAudioSession()
    }

    deinit {
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }

    // MARK: - Public Helpers

    /// Loads and begins playing an episode.
    /// - Parameter episode: The downloaded episode to play.
    func playEpisode(_ episode: DownloadedEpisode) {
        // Save current episode position before switching
        if let current = currentEpisode {
            savePlaybackPosition(for: current, position: currentTime)
        }

        // Clean up old player's time observer BEFORE creating new player
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        currentEpisode = episode

        // Reconstruct the full path from the filename
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(episode.localFilePath)

        // Verify file exists
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            print("Error: Audio file does not exist at path: \(fileURL.path)")
            return
        }

        let playerItem = AVPlayerItem(url: fileURL)
        player = AVPlayer(playerItem: playerItem)
        duration = episode.duration

        // Restore previous playback position, or reset if completed/near end
        var savedPosition = episode.playbackPosition

        // Reset to beginning if episode was completed or within 30 seconds of end
        if episode.isCompleted || (duration - savedPosition < 30 && savedPosition > 0) {
            savedPosition = 0
            episode.playbackPosition = 0
            episode.isCompleted = false
            try? modelContext.save()
        }

        if savedPosition > 0 {
            let time = CMTime(seconds: savedPosition, preferredTimescale: 600)
            player?.seek(to: time)
            currentTime = savedPosition
        } else {
            currentTime = 0
        }

        setupPeriodicTimeObserver()
        play()
    }

    /// Resumes playback.
    func play() {
        // Ensure audio session is active before playing
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }

        guard let player = player else {
            print("Error: No player available")
            return
        }

        player.play()
        isPlaying = true

        // Debug: Check if playback actually started
        print("Player rate after play(): \(player.rate)")
    }

    /// Pauses playback.
    func pause() {
        player?.pause()
        isPlaying = false

        // Save position when pausing
        if let episode = currentEpisode {
            savePlaybackPosition(for: episode, position: currentTime)
        }
    }

    /// Toggles between play and pause states.
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// Seeks to a specific time in the current episode.
    /// - Parameter time: The target time in seconds.
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
    }

    /// Skips forward by a number of seconds.
    /// - Parameter seconds: Number of seconds to skip (default: 15).
    func skipForward(seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    /// Skips backward by a number of seconds.
    /// - Parameter seconds: Number of seconds to skip (default: 15).
    func skipBackward(seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    /// Stops playback and clears the current episode.
    func stop() {
        if let episode = currentEpisode {
            savePlaybackPosition(for: episode, position: currentTime)
        }

        player?.pause()
        player = nil
        currentEpisode = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }

    // MARK: - Private Helpers

    /// Configures the audio session for background playback.
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio)
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    /// Sets up periodic time observation for tracking playback progress.
    private func setupPeriodicTimeObserver() {
        // Add new observer that fires every 0.5 seconds
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds

            // Auto-save position periodically
            if let episode = self.currentEpisode, Int(self.currentTime) % 10 == 0 {
                self.savePlaybackPosition(for: episode, position: self.currentTime)
            }
        }
    }

    /// Saves the current playback position to SwiftData.
    /// - Parameters:
    ///   - episode: The episode being played.
    ///   - position: The current playback position in seconds.
    private func savePlaybackPosition(for episode: DownloadedEpisode, position: TimeInterval) {
        episode.playbackPosition = position

        // Mark as completed if played to within 30 seconds of the end
        if duration - position < 30 {
            episode.isCompleted = true
        }

        try? modelContext.save()
    }
}
