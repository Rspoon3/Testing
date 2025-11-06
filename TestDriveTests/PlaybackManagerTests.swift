import Testing
import SwiftData
@testable import TestDrive

/// Tests for the PlaybackManager.
struct PlaybackManagerTests {
    /// Tests that the playback manager initializes with correct default values.
    @Test func playbackManagerInitializesWithDefaults() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DownloadedEpisode.self, configurations: config)
        let context = container.mainContext

        let manager = PlaybackManager(modelContext: context)

        #expect(manager.currentEpisode == nil, "Should not have a current episode initially")
        #expect(!manager.isPlaying, "Should not be playing initially")
        #expect(manager.currentTime == 0, "Current time should be 0 initially")
        #expect(manager.duration == 0, "Duration should be 0 initially")
    }

    /// Tests that seeking forward increases the current time.
    @Test func skipForwardIncreasesCurrentTime() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DownloadedEpisode.self, configurations: config)
        let context = container.mainContext

        let manager = PlaybackManager(modelContext: context)
        manager.currentTime = 100
        manager.duration = 1000

        manager.skipForward(seconds: 15)

        #expect(manager.currentTime == 115, "Should skip forward 15 seconds")
    }

    /// Tests that seeking backward decreases the current time.
    @Test func skipBackwardDecreasesCurrentTime() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DownloadedEpisode.self, configurations: config)
        let context = container.mainContext

        let manager = PlaybackManager(modelContext: context)
        manager.currentTime = 100
        manager.duration = 1000

        manager.skipBackward(seconds: 15)

        #expect(manager.currentTime == 85, "Should skip backward 15 seconds")
    }

    /// Tests that seeking backward doesn't go below zero.
    @Test func skipBackwardDoesNotGoBelowZero() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DownloadedEpisode.self, configurations: config)
        let context = container.mainContext

        let manager = PlaybackManager(modelContext: context)
        manager.currentTime = 5
        manager.duration = 1000

        manager.skipBackward(seconds: 15)

        #expect(manager.currentTime == 0, "Should not go below 0")
    }

    /// Tests that seeking forward doesn't exceed duration.
    @Test func skipForwardDoesNotExceedDuration() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DownloadedEpisode.self, configurations: config)
        let context = container.mainContext

        let manager = PlaybackManager(modelContext: context)
        manager.currentTime = 995
        manager.duration = 1000

        manager.skipForward(seconds: 15)

        #expect(manager.currentTime == 1000, "Should not exceed duration")
    }

    /// Tests that stop clears the current episode and resets state.
    @Test func stopClearsCurrentEpisode() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: DownloadedEpisode.self, configurations: config)
        let context = container.mainContext

        let manager = PlaybackManager(modelContext: context)

        let episode = DownloadedEpisode(
            episodeID: 1,
            title: "Test Episode",
            episodeDescription: "Description",
            duration: 1000,
            localFilePath: "/test/path.mp3",
            publishDate: .now
        )

        manager.currentEpisode = episode
        manager.isPlaying = true
        manager.currentTime = 500
        manager.duration = 1000

        manager.stop()

        #expect(manager.currentEpisode == nil, "Should clear current episode")
        #expect(!manager.isPlaying, "Should not be playing")
        #expect(manager.currentTime == 0, "Should reset current time")
        #expect(manager.duration == 0, "Should reset duration")
    }
}
