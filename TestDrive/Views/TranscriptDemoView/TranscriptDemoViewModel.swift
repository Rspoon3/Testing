import Foundation
import SwiftUI

/// View model for the transcript demo view.
@Observable
final class TranscriptDemoViewModel {
    /// The audiobook ID to use for the demo.
    let audiobookId: String

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

    /// Whether the comment sheet is showing.
    var showingCommentSheet = false

    /// Comment text being edited.
    var commentText = ""

    /// Saved highlights for the audiobook.
    var highlights: [Highlight] = []

    private let downloader = TranscriptDownloader()
    private let repository = TranscriptRepository()
    private let highlightRepository = HighlightRepository()

    // MARK: - Initializer

    /// Creates a new transcript demo view model.
    /// - Parameter audiobookId: The audiobook identifier to display.
    init(audiobookId: String) {
        self.audiobookId = audiobookId
    }

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

    /// Shows the comment sheet to save a highlight.
    func showCommentSheet() {
        commentText = ""
        showingCommentSheet = true
    }

    /// Saves the current selection as a highlight with the provided comment.
    func saveHighlight() {
        guard let selectionInfo else {
            print("❌ No selection info")
            return
        }
        guard let timestamp = Double(timestampInput) else {
            print("❌ Invalid timestamp")
            return
        }

        print("💾 Attempting to save highlight...")
        print("  - Audiobook ID: \(audiobookId)")
        print("  - Timestamp: \(timestamp)")
        print("  - Selected text: \(selectionInfo.selectedText.prefix(50))...")
        print("  - Segments: \(selectionInfo.affectedSegments.count)")

        do {
            let comment = commentText.isEmpty ? nil : commentText
            let savedHighlight = try highlightRepository.saveHighlight(
                audiobookId: audiobookId,
                timestamp: timestamp,
                highlightedText: selectionInfo.selectedText,
                comment: comment,
                segments: selectionInfo.affectedSegments
            )

            print("✅ Highlight saved with ID: \(savedHighlight.id)")

            // Reload highlights
            loadHighlights()
            print("📚 Loaded \(highlights.count) highlights")

            // Reset state
            showingCommentSheet = false
            commentText = ""
        } catch {
            print("❌ Failed to save highlight: \(error)")
            errorMessage = "Failed to save highlight: \(error.localizedDescription)"
        }
    }

    /// Loads all highlights for the current audiobook.
    func loadHighlights() {
        do {
            highlights = try highlightRepository.highlights(for: audiobookId)
            print("📖 Loaded \(highlights.count) highlights for \(audiobookId)")
        } catch {
            print("❌ Failed to load highlights: \(error)")
            errorMessage = "Failed to load highlights: \(error.localizedDescription)"
        }
    }

    /// Deletes a highlight.
    func deleteHighlight(_ highlight: Highlight) {
        do {
            try highlightRepository.deleteHighlight(highlight.id)
            loadHighlights()
        } catch {
            errorMessage = "Failed to delete highlight: \(error.localizedDescription)"
        }
    }

    /// Clears the transcript and returns to highlights list.
    func clearTranscript() {
        transcriptText = ""
        segments = []
        selectionInfo = nil
        timestampInput = ""
    }
}

// MARK: - Supporting Types

struct SelectionInfo {
    let selectedText: String
    let affectedSegments: [(segment: TranscriptSegment, startOffset: Int, endOffset: Int)]
}
