//
//  MCPToggleRow.swift
//  TestDrive
//

import SwiftUI

/// A single MCP server toggle.
struct MCPToggleRow: View {
    let name: String
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Toggle(isOn: Binding(get: { isEnabled }, set: { onToggle($0) })) {
                EmptyView()
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()

            Text(name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "wrench.and.screwdriver")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .help("MCP server")
        }
    }
}
