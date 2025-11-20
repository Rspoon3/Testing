import Foundation

/// View model for the transcript demo view.
@Observable
final class TranscriptDemoViewModel {
    /// The audiobook ID to use for the demo.
    var audiobookId = "ctx_2iyAq3QN4e7n9Kkt1Q8uyr"

    /// User input for timestamp in seconds.
    var timestampInput = ""

    /// Fetched transcript segments to display.
    var segments: [TranscriptSegment] = []

    /// Whether a download or fetch operation is in progress.
    var isLoading = false

    /// Error message to display to the user.
    var errorMessage: String?

    private let downloader = TranscriptDownloader()
    private let repository = TranscriptRepository()

    // MARK: - Public Helpers

    /// Downloads the transcript if it doesn't exist locally.
    func downloadTranscriptIfNeeded() async {
        // Check if transcript already exists
        guard !repository.transcriptExists(audiobookId: audiobookId) else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await downloader.downloadTranscript(audiobookId: audiobookId)
        } catch {
            errorMessage = "Failed to download transcript: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Fetches transcript segments at the specified timestamp.
    func fetchSegmentsAtTimestamp() {
        guard let timestamp = Double(timestampInput) else {
            errorMessage = "Please enter a valid timestamp in seconds"
            return
        }

        isLoading = true
        errorMessage = nil
        segments = []

        do {
            segments = try repository.segmentsAtTimestamp(
                timestamp,
                audiobookId: audiobookId,
                contextWindow: 30
            )

            if segments.isEmpty {
                errorMessage = "No segments found at timestamp \(timestamp)"
            }
        } catch {
            errorMessage = "Failed to fetch segments: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
