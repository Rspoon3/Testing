//
//  MeetingToastContentTests.swift
//  TestDriveTests
//

import EventKit
import Foundation
import Testing
@testable import TestDrive

@MainActor
struct MeetingToastContentTests {

    /// `event.url` wins over notes and location.
    @Test func prefersExplicitURLField() {
        let event = makeEvent(
            title: "Standup",
            url: URL(string: "https://meet.google.com/abc-defg-hij"),
            notes: "Backup link: https://example.com/ignored",
            location: "https://example.com/also-ignored"
        )

        let content = MeetingToastContent.from(event: event)

        #expect(content.title == "Standup")
        #expect(content.joinURL?.absoluteString == "https://meet.google.com/abc-defg-hij")
    }

    /// When `event.url` is missing, the first URL in the notes is used.
    @Test func extractsZoomURLFromNotes() {
        let zoom = "https://fetchrewards.zoom.us/j/95176772193?jst=2"
        let event = makeEvent(
            title: "Mobile Weekly",
            url: nil,
            notes: """
                Hi team — join here:
                \(zoom)
                Passcode: 1234
                """,
            location: nil
        )

        let content = MeetingToastContent.from(event: event)

        #expect(content.joinURL?.absoluteString == zoom)
    }

    /// Falls back to the location string when notes have no URL.
    @Test func extractsURLFromLocation() {
        let event = makeEvent(
            title: "Lunch sync",
            url: nil,
            notes: "No link in here",
            location: "https://teams.microsoft.com/l/meetup-join/xyz"
        )

        let content = MeetingToastContent.from(event: event)

        #expect(content.joinURL?.absoluteString == "https://teams.microsoft.com/l/meetup-join/xyz")
    }

    /// Events without any URL surface a nil join URL but still produce a usable title.
    @Test func returnsNilJoinURLWhenNoLinkAvailable() {
        let event = makeEvent(
            title: "Heads-down focus",
            url: nil,
            notes: "Just thinking time, no link",
            location: "Home office"
        )

        let content = MeetingToastContent.from(event: event)

        #expect(content.joinURL == nil)
        #expect(content.title == "Heads-down focus")
    }

    /// Missing title falls back to a sensible default.
    @Test func fallsBackToDefaultTitle() {
        let event = makeEvent(title: nil, url: nil, notes: nil, location: nil)

        let content = MeetingToastContent.from(event: event)

        #expect(content.title == "Upcoming meeting")
    }

    // MARK: - Helpers

    private func makeEvent(
        title: String?,
        url: URL?,
        notes: String?,
        location: String?
    ) -> EKEvent {
        let event = EKEvent(eventStore: EKEventStore())
        event.title = title
        event.url = url
        event.notes = notes
        event.location = location
        event.startDate = Date().addingTimeInterval(120)
        event.endDate = Date().addingTimeInterval(120 + 1800)
        return event
    }
}
