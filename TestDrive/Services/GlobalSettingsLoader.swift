//
//  GlobalSettingsLoader.swift
//  TestDrive
//

import Foundation

/// Loads `~/.claude/settings.json`. Outside the sandbox this is normally readable, but inside
/// the sandbox we need a security-scoped bookmark for the user's home directory.
enum GlobalSettingsLoader {
    static var globalSettingsURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".claude/settings.json")
    }

    /// Returns the global settings file if it can be read, or `nil` otherwise.
    static func load() -> ClaudeSettingsFile? {
        try? SettingsFileIO.load(url: globalSettingsURL, scope: .shared)
    }
}
