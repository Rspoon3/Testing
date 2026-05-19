//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import EventKit
import SwiftUI

struct ContentView: View {
    @Bindable var monitor: MeetingMonitor

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Header()
            Divider()
            AuthorizationRow()
            Divider()
            NextMeetingRow()
            Divider()
            SettingsHintRow()
        }
        .padding(24)
        .frame(width: 460)
    }

    // MARK: - Private Views

    private func Header() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Meeting Border")
                .font(.title2.weight(.semibold))
            Text("A red glow appears around your screen \(formattedSeconds(monitor.warningLead)) before each meeting and stays for \(formattedSeconds(monitor.warningDuration)).")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func AuthorizationRow() -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Calendar access")
                    .font(.headline)
                Text(authorizationDescription)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !monitor.isAuthorized {
                Button("Open Settings") {
                    openCalendarPrivacySettings()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func NextMeetingRow() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next meeting")
                .font(.headline)
            if let event = monitor.nextEvent {
                Text(event.title ?? "Untitled")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(countdown(to: event.startDate, from: context.date))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            } else {
                Text("Nothing scheduled in the next 6 hours.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func SettingsHintRow() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Debug")
                    .font(.headline)
                Text("Open Settings (⌘,) to tweak timing or fire the glow on demand.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SettingsLink {
                Text("Open Settings")
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Private Helpers

    private var authorizationDescription: String {
        switch monitor.authorizationStatus {
        case .notDetermined:
            return "Not requested yet — launching the app will prompt you."
        case .restricted:
            return "Restricted by system policy."
        case .denied:
            return "Denied. Grant access in System Settings → Privacy & Security → Calendars."
        case .fullAccess, .authorized:
            return "Full access granted."
        case .writeOnly:
            return "Write-only access — please grant full access so we can read events."
        @unknown default:
            return "Unknown."
        }
    }

    /// Returns a short countdown string from `now` to `target`.
    private func countdown(to target: Date, from now: Date) -> String {
        let remaining = Int(target.timeIntervalSince(now).rounded())
        if remaining <= 0 {
            return "Starting now"
        }
        let minutes = remaining / 60
        let seconds = remaining % 60
        if minutes > 0 {
            return String(format: "Starts in %d:%02d", minutes, seconds)
        }
        return "Starts in \(seconds)s"
    }

    /// Formats a time interval as a human-friendly seconds/minutes string.
    private func formattedSeconds(_ value: TimeInterval) -> String {
        let seconds = Int(value.rounded())
        if seconds >= 60, seconds % 60 == 0 {
            let m = seconds / 60
            return "\(m) min"
        }
        return "\(seconds)s"
    }

    private func openCalendarPrivacySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    ContentView(monitor: MeetingMonitor())
}
