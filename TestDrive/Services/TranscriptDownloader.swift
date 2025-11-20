import Foundation

/// Downloads transcript SQLite databases from the backend server.
@Observable
final class TranscriptDownloader {
    /// The current download state.
    var isDownloading = false

    /// Error message if download fails.
    var errorMessage: String?

    // MARK: - Public Helpers

    /// Downloads a transcript database for the specified audiobook.
    /// - Parameter audiobookId: The unique identifier for the audiobook.
    /// - Returns: The local file URL where the transcript was saved.
    /// - Throws: Network or file system errors.
    func downloadTranscript(audiobookId: String) async throws -> URL {
        isDownloading = true
        errorMessage = nil

        defer {
            isDownloading = false
        }

        // Construct the download URL
        let urlString = "https://vu.santiago.nyc/audiobook/\(audiobookId)/transcript"
        guard let url = URL(string: urlString) else {
            throw TranscriptDownloadError.invalidURL
        }

        // Download the file
        let (tempURL, response) = try await URLSession.shared.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw TranscriptDownloadError.serverError
        }

        // Create transcripts directory
        let fileManager = FileManager.default
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let transcriptsDir = appSupport.appendingPathComponent("transcripts")
        try fileManager.createDirectory(
            at: transcriptsDir,
            withIntermediateDirectories: true
        )

        // Move downloaded file to permanent location
        let destinationURL = transcriptsDir.appendingPathComponent("\(audiobookId).db")

        // Remove existing file if present
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.moveItem(at: tempURL, to: destinationURL)

        print("✅ Transcript downloaded to: \(destinationURL.path)")

        return destinationURL
    }
}

// MARK: - Error Types

enum TranscriptDownloadError: LocalizedError {
    case invalidURL
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid audiobook URL"
        case .serverError:
            return "Server returned an error"
        }
    }
}
