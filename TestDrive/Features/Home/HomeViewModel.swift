//
//  HomeViewModel.swift
//  TestDrive
//

import Foundation

/// View model for the home screen.
@Observable
@MainActor
final class HomeViewModel {
    private(set) var sessions: [RankingSession] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let persistenceService: SessionPersistenceService

    // MARK: - Initializer

    init(persistenceService: SessionPersistenceService = SessionPersistenceService()) {
        self.persistenceService = persistenceService
    }

    // MARK: - Public Helpers

    /// Loads all saved sessions.
    func loadSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            sessions = try await persistenceService.loadAllSessions()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Deletes a session at the specified offsets.
    /// - Parameter offsets: The index set of sessions to delete.
    func deleteSessions(at offsets: IndexSet) async {
        for index in offsets {
            let session = sessions[index]
            do {
                try await persistenceService.delete(id: session.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        // Reload sessions
        await loadSessions()
    }

    /// Returns in-progress sessions (not complete).
    var inProgressSessions: [RankingSession] {
        sessions.filter { !$0.isComplete }
    }

    /// Returns completed sessions.
    var completedSessions: [RankingSession] {
        sessions.filter(\.isComplete)
    }
}
