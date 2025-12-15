//
//  SearchViewModel.swift
//  TestDrive
//

import Foundation

/// View model for the TV show search screen.
@Observable
@MainActor
final class SearchViewModel {
    var searchText = ""
    private(set) var searchResults: [TVShow] = []
    private(set) var isSearching = false
    private(set) var errorMessage: String?

    private let tmdbService: TMDBService
    private var searchTask: Task<Void, Never>?

    // MARK: - Initializer

    init(tmdbService: TMDBService = TMDBService()) {
        self.tmdbService = tmdbService
    }

    // MARK: - Public Helpers

    /// Performs a debounced search for TV shows.
    func search() {
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            // Debounce
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else { return }

            isSearching = true
            errorMessage = nil

            do {
                let results = try await tmdbService.searchShows(query: query)
                guard !Task.isCancelled else { return }
                // Filter to shows with posters for better UX
                searchResults = results.filter { $0.posterPath != nil }
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                searchResults = []
            }

            isSearching = false
        }
    }

    /// Clears the search results.
    func clearSearch() {
        searchText = ""
        searchResults = []
        searchTask?.cancel()
    }
}
