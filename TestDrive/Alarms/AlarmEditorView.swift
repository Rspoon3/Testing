//
//  AlarmEditorView.swift
//  TestDrive
//

import SwiftUI

/// Modal sheet for adding or editing a single `Alarm`. Layout mirrors the
/// system Clock app's alarm editor: time picker → repeat-day strip → label
/// → border style → color → Cancel/Save.
struct AlarmEditorView: View {
    @Binding var alarm: Alarm
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var time: Date

    // MARK: - Initializer

    init(alarm: Binding<Alarm>, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._alarm = alarm
        self.onSave = onSave
        self.onCancel = onCancel
        // Seed the date picker with the alarm's stored hour/minute.
        var comps = DateComponents()
        comps.hour = alarm.wrappedValue.hour
        comps.minute = alarm.wrappedValue.minute
        self._time = State(initialValue: Calendar.current.date(from: comps) ?? Date())
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            TimePicker()
            RepeatStrip()
            Form {
                LabelRow()
                StyleRow()
                if alarm.borderStyle == .fireworks {
                    FireworksColorModeRow()
                }
                if alarm.borderStyle.usesGlowColor {
                    ColorRow()
                }
            }
            .formStyle(.grouped)
            .frame(minHeight: 160)

            ActionsRow()
        }
        .padding(20)
        .frame(width: 460)
        .onChange(of: time) { _, newValue in
            // Mirror the picker's time into the alarm so SAVE persists it.
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            alarm.hour = comps.hour ?? alarm.hour
            alarm.minute = comps.minute ?? alarm.minute
        }
    }

    // MARK: - Private Views

    private func TimePicker() -> some View {
        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
            .labelsHidden()
            .datePickerStyle(.field)
            .font(.system(size: 36, weight: .semibold, design: .rounded))
            .monospacedDigit()
    }

    private func RepeatStrip() -> some View {
        HStack(spacing: 12) {
            Text("Repeat:")
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(Weekday.allCases) { day in
                    let isOn = alarm.weekdays.contains(day)
                    Button {
                        if isOn {
                            alarm.weekdays.remove(day)
                        } else {
                            alarm.weekdays.insert(day)
                        }
                    } label: {
                        Text(day.shortSymbol)
                            .font(.system(size: 12, weight: .semibold))
                            .frame(width: 26, height: 26)
                            .background(isOn ? Color.accentColor : Color.gray.opacity(0.25),
                                        in: .circle)
                            .foregroundStyle(isOn ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
    }

    private func LabelRow() -> some View {
        LabeledContent("Label") {
            TextField("Alarm", text: $alarm.label)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func StyleRow() -> some View {
        LabeledContent("Style") {
            Picker("", selection: $alarm.borderStyle) {
                ForEach(BorderStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .labelsHidden()
        }
    }

    private func FireworksColorModeRow() -> some View {
        LabeledContent("Color mode") {
            Picker("", selection: $alarm.fireworksColorMode) {
                ForEach(FireworksColorMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .labelsHidden()
        }
    }

    private func ColorRow() -> some View {
        LabeledContent(alarm.borderStyle.colorPickerLabel) {
            ColorPicker("", selection: Binding(
                get: { alarm.glowColor },
                set: { alarm.glowColor = $0 }
            ), supportsOpacity: false)
                .labelsHidden()
        }
    }

    private func ActionsRow() -> some View {
        HStack {
            Spacer()
            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            Button("Save", action: onSave)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }
}

#Preview {
    @Previewable @State var alarm = Alarm()
    return AlarmEditorView(
        alarm: $alarm,
        onSave: {},
        onCancel: {}
    )
}
