//
//  AlarmRowView.swift
//  TestDrive
//

import SwiftUI

/// A single row in the alarms list — time + label + repeat days, plus an
/// enabled toggle on the trailing edge. Tapping anywhere outside the toggle
/// is forwarded to `onEdit` to open the editor sheet.
struct AlarmRowView: View {
    @Binding var alarm: Alarm
    let onEdit: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(timeString)
                    .font(.system(size: 30, weight: .regular, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(alarm.isEnabled ? .primary : .secondary)
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onEdit() }

            Toggle("Enabled", isOn: $alarm.isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Private Helpers

    /// "1:07 PM" / "13:07" formatted via the user's current locale.
    private var timeString: String {
        var components = DateComponents()
        components.hour = alarm.hour
        components.minute = alarm.minute
        guard let date = Calendar.current.date(from: components) else { return "—" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// Subtitle that summarises the alarm's repeat days + label. Mirrors
    /// Apple's pattern: `"Every Mon, Wed, Fri — Stand up"` etc.
    private var subtitle: String {
        var pieces: [String] = []
        if alarm.weekdays.isEmpty {
            pieces.append("Once")
        } else if alarm.weekdays == Set(Weekday.allCases) {
            pieces.append("Every day")
        } else if alarm.weekdays == [.monday, .tuesday, .wednesday, .thursday, .friday] {
            pieces.append("Weekdays")
        } else if alarm.weekdays == [.saturday, .sunday] {
            pieces.append("Weekends")
        } else {
            let sorted = alarm.weekdays.sorted { $0.rawValue < $1.rawValue }
            pieces.append(sorted.map(\.abbreviation).joined(separator: ", "))
        }
        if !alarm.label.isEmpty {
            pieces.append(alarm.label)
        }
        return pieces.joined(separator: " — ")
    }
}
