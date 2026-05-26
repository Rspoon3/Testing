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
    private static let timerRange: ClosedRange<Double> = 5...3600

    // MARK: - Body

    var body: some View {
        Form {
            Section("Timing") {
                LeadSlider()
                DurationSlider()
            }

            Section("Appearance") {
                StylePicker()
                if monitor.borderStyle == .fireworks {
                    FireworksColorModePicker()
                }
                if showsColorPicker {
                    ColorPicker(monitor.borderStyle.colorPickerLabel,
                                selection: Binding(get: { monitor.glowColor },
                                                   set: { monitor.glowColor = $0 }),
                                supportsOpacity: false)
                    ResetColorButton()
                }
                Toggle("Show menu bar item",
                       isOn: Binding(get: { monitor.showMenuBarItem },
                                     set: { monitor.showMenuBarItem = $0 }))
            }

            Section("Overlay") {
                OverlayControls()
            }

            Section("Timer") {
                TimerControls()
            }

            Section("Toast") {
                ToastControls()
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Private Helpers

    /// The color picker is hidden for styles that don't use the chosen color, and
    /// also hidden when fireworks aren't on the `.fixed` mode (since the chosen
    /// color is then unused).
    private var showsColorPicker: Bool {
        guard monitor.borderStyle.usesGlowColor else { return false }
        if monitor.borderStyle == .fireworks, monitor.fireworksColorMode != .fixed { return false }
        return true
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

    private func FireworksColorModePicker() -> some View {
        Picker("Color mode",
               selection: Binding(get: { monitor.fireworksColorMode },
                                  set: { monitor.fireworksColorMode = $0 })) {
            ForEach(FireworksColorMode.allCases) { mode in
                Text(mode.title).tag(mode)
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

    private func OverlayControls() -> some View {
        HStack {
            Button("Trigger Overlay") {
                monitor.triggerOverlayForTesting()
            }
            .disabled(monitor.isOverlayVisible)

            Button("Hide Overlay") {
                monitor.dismissOverlay()
            }
            .disabled(!monitor.isOverlayVisible)
        }
    }

    private func TimerControls() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Duration")
                Spacer()
                Text(Duration.seconds(monitor.timerDuration),
                     format: .units(allowed: [.minutes, .seconds], width: .abbreviated))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(get: { monitor.timerDuration }, set: { monitor.timerDuration = $0 }),
                in: Self.timerRange,
                step: 5
            )
            .disabled(monitor.isTimerRunning)

            HStack {
                if monitor.isTimerRunning {
                    Button("Cancel Timer") { monitor.cancelTimer() }
                } else {
                    Button("Start Timer") { monitor.startTimer() }
                }
                Spacer()
                if let fireDate = monitor.timerFireDate {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let remaining = max(0, fireDate.timeIntervalSince(context.date))
                        Text("Fires in \(Duration.seconds(remaining).formattedCountdown())")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
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
