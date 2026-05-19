//
//  DebugSettingsView.swift
//  TestDrive
//

import SwiftUI

/// Settings/debug panel for tweaking the meeting border behavior and firing it on demand.
struct DebugSettingsView: View {
    @Bindable var monitor: MeetingMonitor

    private static let leadRange: ClosedRange<Double> = 5...600
    private static let durationRange: ClosedRange<Double> = 5...300

    // MARK: - Body

    var body: some View {
        Form {
            Section("Timing") {
                LeadSlider()
                DurationSlider()
            }

            Section("Appearance") {
                ColorPicker("Glow color",
                            selection: Binding(get: { monitor.glowColor },
                                               set: { monitor.glowColor = $0 }),
                            supportsOpacity: false)
                ResetColorButton()
            }

            Section("Glow") {
                GlowControls()
            }

            Section("Toast") {
                ToastControls()
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .frame(minHeight: 460)
    }

    // MARK: - Private Views

    private func LeadSlider() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Show how early")
                Spacer()
                Text(formattedSeconds(monitor.warningLead))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(get: { monitor.warningLead }, set: { monitor.warningLead = $0 }),
                in: Self.leadRange,
                step: 5
            )
        }
    }

    private func DurationSlider() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Stay on screen")
                Spacer()
                Text(formattedSeconds(monitor.warningDuration))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(get: { monitor.warningDuration }, set: { monitor.warningDuration = $0 }),
                in: Self.durationRange,
                step: 5
            )
        }
    }

    private func ResetColorButton() -> some View {
        Button("Reset to red") {
            monitor.glowColor = .red
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.tint)
    }

    private func GlowControls() -> some View {
        HStack {
            Button("Trigger Glow") {
                monitor.triggerOverlayForTesting()
            }
            .disabled(monitor.isOverlayVisible)

            Button("Hide Glow") {
                monitor.dismissOverlay()
            }
            .disabled(!monitor.isOverlayVisible)
        }
    }

    private func ToastControls() -> some View {
        HStack {
            Button("Trigger Toast") {
                monitor.triggerToastForTesting()
            }
            .disabled(monitor.isToastVisible)

            Button("Hide Toast") {
                monitor.dismissToast()
            }
            .disabled(!monitor.isToastVisible)
        }
    }

    // MARK: - Private Helpers

    /// Formats a time interval as a human-friendly seconds/minutes string.
    private func formattedSeconds(_ value: TimeInterval) -> String {
        let seconds = Int(value.rounded())
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes == 0 {
            return "\(seconds)s"
        }
        if remainder == 0 {
            return "\(minutes) min"
        }
        return "\(minutes)m \(remainder)s"
    }
}

#Preview {
    DebugSettingsView(monitor: MeetingMonitor())
}
