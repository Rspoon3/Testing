//
//  ShowDetailViewModel.swift
//  TestDrive
//

import Foundation

/// View model for the show detail screen.
@Observable
@MainActor
final class ShowDetailViewModel {
    let show: TVShow
    private(set) var episodes: [Episode] = []
    private(set) var isLoading = false
    var errorMessage: String?
    private(set) var createdSession: RankingSession?

    private let tmdbService: TMDBService
    private let persistenceService: SessionPersistenceService

    // MARK: - Initializer

    init(
        show: TVShow,
        tmdbService: TMDBService = TMDBService(),
        persistenceService: SessionPersistenceService = SessionPersistenceService()
    ) {
        self.show = show
        self.tmdbService = tmdbService
        self.persistenceService = persistenceService
    }

    // MARK: - Public Helpers

    /// Fetches all episodes for the show.
    func fetchEpisodes() async {
        isLoading = true
        errorMessage = nil

        do {
            episodes = try await tmdbService.getAllEpisodes(for: show)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Creates a new ranking session and saves it.
    /// - Returns: The created session.
    func createSession() async throws -> RankingSession {
        let session = RankingSession(
            showId: show.id,
            showName: show.name,
            showPosterPath: show.posterPath,
            episodes: episodes
        )

        try await persistenceService.save(session)
        createdSession = session
        return session
    }

    /// The total number of episodes.
    var episodeCount: Int {
        episodes.count
    }

    /// The estimated number of comparisons needed.
    var estimatedComparisons: Int {
        max(episodes.count - 1, 0)
    }
}
