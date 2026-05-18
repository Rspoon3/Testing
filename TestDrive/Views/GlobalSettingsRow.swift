//
//  GlobalSettingsRow.swift
//  TestDrive
//

import SwiftUI

/// Read-only header showing the plugins enabled in `~/.claude/settings.json`. These apply to every
/// directory and we don't write the global file from this app.
struct GlobalSettingsRow: View {
    let file: ClaudeSettingsFile

    @State private var isExpanded = false

    // MARK: - Body

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(file.enabledPlugins.sorted(by: { $0.key < $1.key }), id: \.key) { entry in
                    HStack {
                        Image(systemName: entry.value ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(entry.value ? .green : .secondary)
                        Text(entry.key)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 4)
        } label: {
            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(.tint)
                Text("Global (~/.claude/settings.json)")
                    .font(.callout)
                    .fontWeight(.medium)
                Spacer()
                Text("\(file.enabledPlugins.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
    }
}
