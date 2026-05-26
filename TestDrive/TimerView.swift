//
//  TimerView.swift
//  TestDrive
//

import SwiftUI

/// Standalone Timer tab — big HH:MM:SS display with hr/min/sec steppers
/// underneath and a Cancel/Start row at the bottom. Mirrors the layout of
/// the system Clock app's Timers tab.
struct TimerView: View {
    @Bindable var monitor: MeetingMonitor

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            ColumnLabels()
            BigDisplay()
            EditorRow()
            Spacer(minLength: 0)
            ActionsRow()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Private Views

    private func ColumnLabels() -> some View {
        HStack(spacing: 0) {
            Text("hr").frame(maxWidth: .infinity)
            Text("min").frame(maxWidth: .infinity)
            Text("sec").frame(maxWidth: .infinity)
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .frame(maxWidth: 360)
    }

    private func BigDisplay() -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = remainingSeconds(at: context.date)
            Text(formatted(seconds: remaining))
                .font(.system(size: 64, weight: .light, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.default, value: remaining)
        }
    }

    /// Hours / minutes / seconds editors shown beneath the big display while
    /// the timer is *not* running. Hidden during the countdown so the screen
    /// is uncluttered.
    @ViewBuilder
    private func EditorRow() -> some View {
        if !monitor.isTimerRunning {
            HStack(spacing: 16) {
                Stepper(value: hoursBinding, in: 0...23) {
                    Text("Hours: \(hours)").monospacedDigit()
                }
                Stepper(value: minutesBinding, in: 0...59) {
                    Text("Min: \(minutes)").monospacedDigit()
                }
                Stepper(value: secondsBinding, in: 0...59, step: 5) {
                    Text("Sec: \(seconds)").monospacedDigit()
                }
            }
            .labelsHidden()
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    private func ActionsRow() -> some View {
        HStack(spacing: 12) {
            Button {
                monitor.cancelTimer()
            } label: {
                Text("Cancel")
                    .frame(minWidth: 120)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(!monitor.isTimerRunning)

            Button {
                monitor.startTimer()
            } label: {
                Text("Start")
                    .frame(minWidth: 120)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(monitor.isTimerRunning || monitor.timerDuration < 1)
        }
    }

    // MARK: - Private Helpers

    private var hours: Int { Int(monitor.timerDuration) / 3600 }
    private var minutes: Int { (Int(monitor.timerDuration) % 3600) / 60 }
    private var seconds: Int { Int(monitor.timerDuration) % 60 }

    private var hoursBinding: Binding<Int> {
        Binding(get: { hours }, set: { setComponents(hours: $0, minutes: minutes, seconds: seconds) })
    }

    private var minutesBinding: Binding<Int> {
        Binding(get: { minutes }, set: { setComponents(hours: hours, minutes: $0, seconds: seconds) })
    }

    private var secondsBinding: Binding<Int> {
        Binding(get: { seconds }, set: { setComponents(hours: hours, minutes: minutes, seconds: $0) })
    }

    private func setComponents(hours: Int, minutes: Int, seconds: Int) {
        let total = max(0, hours) * 3600 + max(0, minutes) * 60 + max(0, seconds)
        monitor.timerDuration = TimeInterval(max(1, total))
    }

    /// Remaining seconds to display in the big readout. Counts down while the
    /// timer is armed, otherwise shows the currently-set duration.
    private func remainingSeconds(at date: Date) -> Int {
        if let fireDate = monitor.timerFireDate {
            return max(0, Int(fireDate.timeIntervalSince(date).rounded()))
        }
        return Int(monitor.timerDuration)
    }

    private func formatted(seconds total: Int) -> String {
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

#Preview {
    TimerView(monitor: MeetingMonitor())
        .frame(width: 560, height: 540)
}
