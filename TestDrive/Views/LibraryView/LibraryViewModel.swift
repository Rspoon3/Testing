import Foundation

/// View model for managing the audiobook library.
@Observable
final class LibraryViewModel {
    private let audiobookRepository = AudiobookRepository()
    private let transcriptDownloader = TranscriptDownloader()

    var audiobooks: [Audiobook] = []
    var isLoading = false
    var errorMessage: String?

    var showingDownloadSheet = false
    var audiobookIdInput = ""
    var isDownloading = false
    var downloadError: String?

    // MARK: - Public Helpers

    /// Loads all available audiobooks from the transcripts directory.
    func loadAudiobooks() {
        isLoading = true
        errorMessage = nil

        do {
            audiobooks = try audiobookRepository.discoverAudiobooks()
        } catch {
            errorMessage = "Failed to load audiobooks: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Updates the last accessed timestamp for an audiobook.
    /// - Parameter audiobookId: The audiobook identifier.
    func didSelectAudiobook(_ audiobookId: String) {
        audiobookRepository.updateLastAccessed(for: audiobookId)
    }

    /// Downloads a transcript for the entered audiobook ID.
    func downloadTranscript() async {
        isDownloading = true
        downloadError = nil

        do {
            _ = try await transcriptDownloader.downloadTranscript(audiobookId: audiobookIdInput)

            // Reload audiobooks to show the newly downloaded one
            loadAudiobooks()

            // Close the sheet
            showingDownloadSheet = false
            audiobookIdInput = ""
        } catch {
            downloadError = "Failed to download: \(error.localizedDescription)"
        }

        isDownloading = false
    }

    /// Cancels the download and closes the sheet.
    func cancelDownload() {
        showingDownloadSheet = false
        audiobookIdInput = ""
        downloadError = nil
    }
}
