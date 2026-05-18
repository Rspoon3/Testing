//
//  DirectoryRow.swift
//  TestDrive
//

import SwiftUI

/// Expandable row that shows a single `.claude` directory and its toggleable plugins / MCP servers.
struct DirectoryRow: View {
    let directory: ClaudeDirectory
    @Bindable var viewModel: AppViewModel

    @State private var isExpanded = false

    // MARK: - Body

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            details
        } label: {
            label
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Private Views

    private var label: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(directory.displayName)
                .font(.callout)
                .fontWeight(.medium)
            Text(directory.path)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var details: some View {
        let plugins = mergedPlugins
        let mcpServers = directory.declaredMcpServers

        VStack(alignment: .leading, spacing: 8) {
            if plugins.isEmpty && mcpServers.isEmpty {
                Text("No project overrides. Inherits global plugins.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                if !plugins.isEmpty {
                    sectionHeader("Plugins")
                    ForEach(plugins.sorted(by: { $0.key < $1.key }), id: \.key) { entry in
                        PluginToggleRow(
                            identifier: entry.key,
                            isEnabled: entry.value,
                            origin: origin(for: entry.key)
                        ) { newValue in
                            viewModel.togglePlugin(in: directory, identifier: entry.key, enabled: newValue)
                        } onClear: {
                            viewModel.clearPluginOverride(in: directory, identifier: entry.key)
                        }
                    }
                }
                if !mcpServers.isEmpty {
                    sectionHeader("MCP Servers")
                    ForEach(mcpServers.sorted(by: { $0.key < $1.key }), id: \.key) { entry in
                        MCPToggleRow(
                            name: entry.key,
                            isEnabled: entry.value
                        ) { newValue in
                            viewModel.toggleMcpServer(in: directory, name: entry.key, enabled: newValue)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.leading, 12)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Private Helpers

    private var mergedPlugins: [String: Bool] {
        var merged = viewModel.globalSettings?.enabledPlugins ?? [:]
        for (key, value) in directory.declaredPlugins {
            merged[key] = value
        }
        return merged
    }

    private func origin(for identifier: String) -> PluginToggleRow.Origin {
        if directory.local?.enabledPlugins[identifier] != nil { return .local }
        if directory.shared?.enabledPlugins[identifier] != nil { return .shared }
        return .global
    }
}
