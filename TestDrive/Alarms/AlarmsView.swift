//
//  AlarmsView.swift
//  TestDrive
//

import SwiftUI

/// Alarms tab — lists every user-defined alarm with an enabled toggle,
/// plus a `+` button that opens `AlarmEditorView` as a modal sheet for
/// adding or editing one.
struct AlarmsView: View {
    @Bindable var monitor: MeetingMonitor

    /// The alarm currently being edited (either a brand-new one from `+` or
    /// an existing one selected in the list). Bound through to
    /// `AlarmEditorView` and committed back on save.
    @State private var draft: Alarm?
    /// `true` when `draft` is a brand-new alarm vs an edit of an existing
    /// row — controls whether Save inserts or updates.
    @State private var isNew = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            Header()
            if monitor.alarms.isEmpty {
                EmptyState()
            } else {
                List {
                    ForEach($monitor.alarms) { $alarm in
                        AlarmRowView(alarm: $alarm) {
                            beginEdit(alarm)
                        }
                    }
                    .onDelete { indexSet in
                        monitor.alarms.remove(atOffsets: indexSet)
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $draft) { _ in
            AlarmEditorView(
                alarm: Binding(
                    get: { draft ?? Alarm() },
                    set: { draft = $0 }
                ),
                onSave: commitDraft,
                onCancel: { draft = nil }
            )
        }
    }

    // MARK: - Private Views

    private func Header() -> some View {
        HStack {
            Text("Alarms")
                .font(.title2.weight(.semibold))
            Spacer()
            Button {
                draft = Alarm()
                isNew = true
            } label: {
                Label("Add Alarm", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .font(.title3)
            .accessibilityLabel("Add Alarm")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func EmptyState() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "alarm")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No alarms yet")
                .font(.headline)
            Text("Tap + to add an alarm that fires the overlay at a specific time.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Private Helpers

    private func beginEdit(_ alarm: Alarm) {
        draft = alarm
        isNew = false
    }

    private func commitDraft() {
        guard let draft else { return }
        if isNew {
            monitor.alarms.append(draft)
        } else if let index = monitor.alarms.firstIndex(where: { $0.id == draft.id }) {
            monitor.alarms[index] = draft
        }
        self.draft = nil
    }
}

#Preview {
    AlarmsView(monitor: MeetingMonitor())
        .frame(width: 480, height: 540)
}
