//
//  ClaudeDirectory.swift
//  TestDrive
//

import Foundation

/// A project directory that contains a `.claude/` folder, plus the parsed settings files inside it.
struct ClaudeDirectory: Identifiable, Hashable, Sendable {
    /// Directory containing the `.claude/` folder (the project root from a user's perspective).
    let url: URL
    var shared: ClaudeSettingsFile?
    var local: ClaudeSettingsFile?

    // MARK: - Identifiable

    var id: URL { url }

    // MARK: - Display

    var displayName: String { url.lastPathComponent }

    var path: String { url.path(percentEncoded: false) }

    // MARK: - Plugin aggregation

    /// Plugins explicitly toggled in either settings file (project values win over local for display purposes,
    /// but writes target the local file). Returns `[identifier: isEnabled]`.
    var declaredPlugins: [String: Bool] {
        var merged: [String: Bool] = [:]
        for (key, value) in shared?.enabledPlugins ?? [:] { merged[key] = value }
        for (key, value) in local?.enabledPlugins ?? [:] { merged[key] = value }
        return merged
    }

    /// MCP servers explicitly enabled or disabled at the project level. Returns the union of the
    /// shared + local entries with their effective enabled flag.
    var declaredMcpServers: [String: Bool] {
        var merged: [String: Bool] = [:]
        for name in shared?.enabledMcpServers ?? [] { merged[name] = true }
        for name in shared?.disabledMcpServers ?? [] { merged[name] = false }
        for name in local?.enabledMcpServers ?? [] { merged[name] = true }
        for name in local?.disabledMcpServers ?? [] { merged[name] = false }
        return merged
    }
}
