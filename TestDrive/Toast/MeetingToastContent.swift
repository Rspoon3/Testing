//
//  MeetingToastContent.swift
//  TestDrive
//

import EventKit
import Foundation

/// Information shown on the meeting toast.
struct MeetingToastContent: Equatable {
    /// Title displayed prominently on the toast.
    var title: String

    /// Optional URL (typically Zoom/Meet/Teams) surfaced as a "Join" button.
    var joinURL: URL?

    /// Meeting start time used to drive the countdown text. `nil` means no countdown.
    var startsAt: Date?

    /// Builds a toast model from a real calendar event, extracting a meeting URL when possible.
    /// - Parameter event: The event to summarize.
    static func from(event: EKEvent) -> MeetingToastContent {
        let rawTitle = event.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return MeetingToastContent(
            title: rawTitle.isEmpty ? "Upcoming meeting" : rawTitle,
            joinURL: event.firstMeetingURL,
            startsAt: event.startDate
        )
    }
}
