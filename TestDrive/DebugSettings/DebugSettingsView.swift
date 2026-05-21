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
                StylePicker()
                if monitor.borderStyle == .colored {
                    ColorPicker("Glow color",
                                selection: Binding(get: { monitor.glowColor },
                                                   set: { monitor.glowColor = $0 }),
                                supportsOpacity: false)
                    ResetColorButton()
                }
                Toggle("Show menu bar item",
                       isOn: Binding(get: { monitor.showMenuBarItem },
                                     set: { monitor.showMenuBarItem = $0 }))
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
                Text(Duration.seconds(monitor.warningLead),
                     format: .units(allowed: [.minutes, .seconds], width: .abbreviated))
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
                Text(Duration.seconds(monitor.warningDuration),
                     format: .units(allowed: [.minutes, .seconds], width: .abbreviated))
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

    private func StylePicker() -> some View {
        Picker("Border style",
               selection: Binding(get: { monitor.borderStyle },
                                  set: { monitor.borderStyle = $0 })) {
            ForEach(BorderStyle.allCases) { style in
                Text(style.title).tag(style)
            }
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
}

#Preview {
    DebugSettingsView(monitor: MeetingMonitor())
}
