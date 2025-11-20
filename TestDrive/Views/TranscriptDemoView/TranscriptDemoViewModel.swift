import Foundation
import SwiftUI

/// View model for the transcript demo view.
@Observable
final class TranscriptDemoViewModel {
    /// The audiobook ID to use for the demo.
    var audiobookId = "ctx_2iyAq3QN4e7n9Kkt1Q8uyr"

    /// User input for timestamp in seconds.
    var timestampInput = ""

    /// Fetched transcript segments to display.
    var segments: [TranscriptSegment] = []

    /// Combined transcript text for selection.
    var transcriptText = ""

    /// Current text selection range.
    var selectedRange: NSRange?

    /// Information about the selected text and segments.
    var selectionInfo: SelectionInfo?

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
        transcriptText = ""
        selectionInfo = nil

        do {
            segments = try repository.segmentsAtTimestamp(
                timestamp,
                audiobookId: audiobookId,
                contextWindow: 30
            )

            if segments.isEmpty {
                errorMessage = "No segments found at timestamp \(timestamp)"
            } else {
                // Combine all segment text
                transcriptText = segments.map(\.text).joined(separator: " ")
            }
        } catch {
            errorMessage = "Failed to fetch segments: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Updates selection information based on the current selection range.
    func updateSelectionInfo(range: NSRange) {
        selectedRange = range
        guard range.length > 0 else {
            selectionInfo = nil
            return
        }

        // Find which segments this selection spans
        var currentPosition = 0
        var affectedSegments: [(segment: TranscriptSegment, startOffset: Int, endOffset: Int)] = []

        for segment in segments {
            let segmentLength = segment.text.count
            let segmentRange = NSRange(location: currentPosition, length: segmentLength)

            // Check if selection intersects with this segment
            let intersection = NSIntersectionRange(range, segmentRange)
            if intersection.length > 0 {
                let startOffset = intersection.location - segmentRange.location
                let endOffset = startOffset + intersection.length

                affectedSegments.append((segment, startOffset, endOffset))
            }

            currentPosition += segmentLength + 1 // +1 for the space separator
        }

        if !affectedSegments.isEmpty {
            let selectedText = (transcriptText as NSString).substring(with: range)
            selectionInfo = SelectionInfo(
                selectedText: selectedText,
                affectedSegments: affectedSegments
            )
        } else {
            selectionInfo = nil
        }
    }
}

// MARK: - Supporting Types

struct SelectionInfo {
    let selectedText: String
    let affectedSegments: [(segment: TranscriptSegment, startOffset: Int, endOffset: Int)]
}
