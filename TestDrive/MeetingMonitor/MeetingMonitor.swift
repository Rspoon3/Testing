//
//  MeetingMonitor.swift
//  TestDrive
//
//  Watches the user's calendar and triggers a red glowing border overlay (plus a
//  drop-down toast) shortly before each upcoming meeting starts.
//

import AppKit
import EventKit
import Observation
import SwiftUI

/// Observes the user's calendar and surfaces a warning overlay shortly before each meeting begins.
///
/// The monitor refreshes events on a regular cadence (so newly-added meetings are picked up)
/// and ticks once per second to fire the overlay at the right moment.
@MainActor
@Observable
final class MeetingMonitor {

    /// How far ahead we look for upcoming meetings.
    private static let lookAheadWindow: TimeInterval = 60 * 60 * 6

    /// How often we re-query the calendar for new/changed events.
    private static let refreshInterval: TimeInterval = 60

    /// How early before an event the overlay should appear (seconds). Persisted across launches.
    var warningLead: TimeInterval {
        didSet { settings.warningLead = warningLead }
    }

    /// How long the overlay stays on screen (seconds). Persisted across launches.
    var warningDuration: TimeInterval {
        didSet { settings.warningDuration = warningDuration }
    }

    /// Color used for the border + toast accent. Persisted across launches.
    var glowColor: Color {
        didSet { settings.glowColor = glowColor }
    }

    /// Whether the menu bar item is shown. Persisted across launches.
    var showMenuBarItem: Bool {
        didSet {
            settings.showMenuBarItem = showMenuBarItem
            updateMenuBarCountdown()
        }
    }

    /// Visual treatment used for the warning overlay. Persisted across launches.
    var borderStyle: BorderStyle {
        didSet { settings.borderStyle = borderStyle }
    }

    /// How the fireworks overlay colors its explosions. Persisted.
    var fireworksColorMode: FireworksColorMode {
        didSet { settings.fireworksColorMode = fireworksColorMode }
    }

    /// Current calendar authorization status.
    var authorizationStatus: EKAuthorizationStatus

    /// The next upcoming meeting, if any.
    var nextEvent: EKEvent?

    /// Whether the warning overlay is currently visible.
    var isOverlayVisible: Bool = false

    /// Whether the meeting toast is currently visible.
    var isToastVisible: Bool = false

    /// Pre-formatted countdown string shown in the menu bar label. `nil` when
    /// there is no upcoming meeting or the menu bar item is hidden.
    var menuBarCountdown: String?

    @ObservationIgnored private let store = EKEventStore()
    @ObservationIgnored private let overlay: GlowingBorderController
    @ObservationIgnored private let toast: MeetingToastController
    @ObservationIgnored private var settings: PersistedSettings
    @ObservationIgnored private var events: [EKEvent] = []
    @ObservationIgnored private var firedEventIDs: Set<String> = []
    @ObservationIgnored private var lastRefresh: Date = .distantPast
    @ObservationIgnored private var tickTimer: Timer?
    @ObservationIgnored private var overlayDismissTimer: Timer?
    @ObservationIgnored nonisolated(unsafe) private var changeObserver: (any NSObjectProtocol)?

    // MARK: - Initializer

    /// Creates a monitor that drives the supplied overlay + toast controllers.
    init(
        overlay: GlowingBorderController? = nil,
        toast: MeetingToastController? = nil,
        settings: PersistedSettings = .live
    ) {
        self.overlay = overlay ?? GlowingBorderController()
        self.toast = toast ?? MeetingToastController()
        self.settings = settings
        self.warningLead = settings.warningLead
        self.warningDuration = settings.warningDuration
        self.glowColor = settings.glowColor
        self.showMenuBarItem = settings.showMenuBarItem
        self.borderStyle = settings.borderStyle
        self.fireworksColorMode = settings.fireworksColorMode
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)

        changeObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshEvents(force: true) }
        }
    }

    nonisolated deinit {
        if let changeObserver {
            NotificationCenter.default.removeObserver(changeObserver)
        }
    }

    // MARK: - Public Helpers

    /// Requests calendar access and begins monitoring upcoming meetings.
    func start() async {
        await requestAccessIfNeeded()
        guard isAuthorized else { return }
        refreshEvents(force: true)
        startTicking()
    }

    /// Shows the glow overlay immediately for the current warning duration. Useful for debugging.
    func triggerOverlayForTesting() {
        showOverlay()
    }

    /// Shows the toast with sample content (or the next real event, if one is available).
    func triggerToastForTesting() {
        let content: MeetingToastContent
        if let nextEvent {
            content = .from(event: nextEvent)
        } else {
            content = MeetingToastContent(
                title: "Mobile Weekly Sync",
                joinURL: URL(string: "https://fetchrewards.zoom.us/j/95176772193?jst=2"),
                startsAt: Date().addingTimeInterval(warningLead)
            )
        }
        showToast(content)
    }

    /// Hides the glow overlay immediately.
    func dismissOverlay() {
        hideOverlay()
    }

    /// Hides the meeting toast immediately.
    func dismissToast() {
        toast.hide()
        isToastVisible = false
    }

    /// Whether calendar access has been granted at any level the app can use.
    var isAuthorized: Bool {
        switch authorizationStatus {
        case .fullAccess, .authorized, .writeOnly:
            return true
        default:
            return false
        }
    }

    // MARK: - Private Helpers

    private func requestAccessIfNeeded() async {
        guard !isAuthorized else { return }
        do {
            _ = try await store.requestFullAccessToEvents()
        } catch {
            // Swallow — UI reflects the resulting status.
        }
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    private func startTicking() {
        tickTimer?.invalidate()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    private func tick() {
        if Date().timeIntervalSince(lastRefresh) >= Self.refreshInterval {
            refreshEvents(force: false)
        }
        checkForUpcomingMeetings()
        updateMenuBarCountdown()
    }

    private func updateMenuBarCountdown() {
        guard showMenuBarItem, let nextEvent else {
            if menuBarCountdown != nil { menuBarCountdown = nil }
            return
        }
        let secondsUntil = Int(nextEvent.startDate.timeIntervalSinceNow.rounded())
        guard secondsUntil > 0, secondsUntil <= 60 * 60 else {
            if menuBarCountdown != nil { menuBarCountdown = nil }
            return
        }
        let formatted = Duration.seconds(secondsUntil).formattedCountdown()
        if menuBarCountdown != formatted {
            menuBarCountdown = formatted
        }
    }

    private func refreshEvents(force: Bool) {
        guard isAuthorized else { return }
        let now = Date()
        let end = now.addingTimeInterval(Self.lookAheadWindow)
        let calendars = store.calendars(for: .event)
        let predicate = store.predicateForEvents(withStart: now.addingTimeInterval(-warningDuration),
                                                 end: end,
                                                 calendars: calendars)
        let fetched = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
        events = fetched
        nextEvent = fetched.first { $0.startDate > now }
        lastRefresh = now

        // Prune fired IDs that no longer correspond to upcoming events.
        let liveIDs = Set(fetched.compactMap(\.eventIdentifier))
        firedEventIDs.formIntersection(liveIDs)

        updateMenuBarCountdown()
    }

    private func checkForUpcomingMeetings() {
        let now = Date()
        for event in events {
            guard let id = event.eventIdentifier, !firedEventIDs.contains(id) else { continue }
            let timeUntilStart = event.startDate.timeIntervalSince(now)
            if timeUntilStart <= warningLead && timeUntilStart > -warningDuration {
                firedEventIDs.insert(id)
                showOverlay()
                showToast(.from(event: event))
            }
        }
    }

    private func showOverlay() {
        overlay.show(color: glowColor, style: borderStyle, fireworksColorMode: fireworksColorMode)
        isOverlayVisible = true
        overlayDismissTimer?.invalidate()
        let timer = Timer(timeInterval: warningDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.hideOverlay() }
        }
        RunLoop.main.add(timer, forMode: .common)
        overlayDismissTimer = timer
    }

    private func hideOverlay() {
        overlay.hide()
        isOverlayVisible = false
        overlayDismissTimer?.invalidate()
        overlayDismissTimer = nil
    }

    private func showToast(_ content: MeetingToastContent) {
        isToastVisible = true
        toast.show(content) { [weak self] url in
            NSWorkspace.shared.open(url)
            self?.isToastVisible = false
        } onDismiss: { [weak self] in
            self?.isToastVisible = false
        }
    }
}
