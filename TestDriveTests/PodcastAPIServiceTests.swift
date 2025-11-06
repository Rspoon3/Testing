import Testing
import Foundation
@testable import TestDrive

/// Tests for the PodcastAPIService.
struct PodcastAPIServiceTests {
    /// Tests that the API service can successfully fetch episodes.
    @Test func fetchEpisodesReturnsResults() async throws {
        let service = PodcastAPIService()

        let episodes = try await service.fetchEpisodes(limit: 10)

        #expect(!episodes.isEmpty, "Should return at least one episode")
        #expect(episodes.count <= 10, "Should respect the limit parameter")
    }

    /// Tests that episodes are sorted by publish date (newest first).
    @Test func fetchEpisodesAreSortedByDate() async throws {
        let service = PodcastAPIService()

        let episodes = try await service.fetchEpisodes(limit: 20)

        guard episodes.count >= 2 else {
            return
        }

        for i in 0..<(episodes.count - 1) {
            #expect(
                episodes[i].publishDate >= episodes[i + 1].publishDate,
                "Episodes should be sorted by publish date, newest first"
            )
        }
    }

    /// Tests that fetched episodes have valid data.
    @Test func fetchedEpisodesHaveValidData() async throws {
        let service = PodcastAPIService()

        let episodes = try await service.fetchEpisodes(limit: 5)

        for episode in episodes {
            #expect(!episode.title.isEmpty, "Episode title should not be empty")
            #expect(episode.duration > 0, "Episode duration should be positive")
            #expect(episode.id > 0, "Episode ID should be positive")
        }
    }
}
