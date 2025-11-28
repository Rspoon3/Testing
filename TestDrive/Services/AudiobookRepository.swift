import Foundation

/// Repository for discovering and managing audiobook metadata.
struct AudiobookRepository {
    private let highlightRepository = HighlightRepository()

    // MARK: - Public Helpers

    /// Discovers all audiobooks by scanning the transcripts directory.
    /// - Returns: Array of audiobooks sorted by last accessed date.
    func discoverAudiobooks() throws -> [Audiobook] {
        let transcriptsDirectory = try transcriptsDirectoryURL()

        guard FileManager.default.fileExists(atPath: transcriptsDirectory.path) else {
            return []
        }

        let files = try FileManager.default.contentsOfDirectory(
            at: transcriptsDirectory,
            includingPropertiesForKeys: nil
        )

        let audiobookIds = files
            .filter { $0.pathExtension == "db" }
            .map { $0.deletingPathExtension().lastPathComponent }

        return try audiobookIds.map { audiobookId in
            let highlightCount = try highlightCount(for: audiobookId)
            let lastAccessed = lastAccessedDate(for: audiobookId)

            return Audiobook(
                id: audiobookId,
                highlightCount: highlightCount,
                lastAccessed: lastAccessed
            )
        }
        .sorted()
    }

    /// Gets the number of highlights for a specific audiobook.
    /// - Parameter audiobookId: The audiobook identifier.
    /// - Returns: The count of highlights.
    func highlightCount(for audiobookId: String) throws -> Int {
        let highlights = try highlightRepository.highlights(for: audiobookId)
        return highlights.count
    }

    /// Updates the last accessed timestamp for an audiobook.
    /// - Parameter audiobookId: The audiobook identifier.
    func updateLastAccessed(for audiobookId: String) {
        UserDefaults.standard.set(Date(), forKey: lastAccessedKey(for: audiobookId))
    }

    // MARK: - Private Helpers

    /// Gets the last accessed date for an audiobook.
    /// - Parameter audiobookId: The audiobook identifier.
    /// - Returns: The last accessed date, or the distant past if never accessed.
    private func lastAccessedDate(for audiobookId: String) -> Date {
        UserDefaults.standard.object(forKey: lastAccessedKey(for: audiobookId)) as? Date ?? .distantPast
    }

    /// Creates the UserDefaults key for storing last accessed timestamp.
    /// - Parameter audiobookId: The audiobook identifier.
    /// - Returns: The UserDefaults key string.
    private func lastAccessedKey(for audiobookId: String) -> String {
        "lastAccessed_\(audiobookId)"
    }

    /// Gets the URL for the transcripts directory.
    /// - Returns: URL to the transcripts directory.
    /// - Throws: File system errors.
    private func transcriptsDirectoryURL() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return appSupport.appendingPathComponent("transcripts")
    }
}
