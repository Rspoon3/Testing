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
            Text("A red glow appears around your screen \(Duration.seconds(monitor.warningLead), format: .units(allowed: [.minutes, .seconds], width: .abbreviated)) before each meeting and stays for \(Duration.seconds(monitor.warningDuration), format: .units(allowed: [.minutes, .seconds], width: .abbreviated)).")
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
                    let remaining = event.startDate.timeIntervalSince(context.date)
                    if remaining <= 0 {
                        Text("Starting now")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Starts in \(Duration.seconds(remaining), format: .time(pattern: .minuteSecond))")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
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
