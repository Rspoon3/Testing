//
//  PluginToggleRow.swift
//  TestDrive
//

import SwiftUI

/// A single plugin toggle row, with a hint indicating whether the value comes from the global,
/// shared, or local settings file and an option to clear the per-directory override.
struct PluginToggleRow: View {
    enum Origin: String {
        case global
        case shared
        case local

        var label: String {
            switch self {
            case .global: "global"
            case .shared: "shared"
            case .local: "local"
            }
        }

        var color: Color {
            switch self {
            case .global: .secondary
            case .shared: .orange
            case .local: .accentColor
            }
        }
    }

    let identifier: String
    let isEnabled: Bool
    let origin: Origin
    let onToggle: (Bool) -> Void
    let onClear: () -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Toggle(isOn: Binding(get: { isEnabled }, set: { onToggle($0) })) {
                EmptyView()
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 0) {
                Text(identifier)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(origin.label)
                    .font(.caption2)
                    .foregroundStyle(origin.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if origin == .local {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .buttonStyle(.borderless)
                .help("Remove the per-directory override")
            }
        }
    }
}
