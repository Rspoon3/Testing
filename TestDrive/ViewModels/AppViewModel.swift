//
//  AppViewModel.swift
//  TestDrive
//

import Foundation
import Observation

/// Owns the menu bar app's mutable state and coordinates between the bookmark store,
/// directory scanner, and settings file IO.
@MainActor
@Observable
final class AppViewModel {
    private(set) var directories: [ClaudeDirectory] = []
    private(set) var globalSettings: ClaudeSettingsFile?
    private(set) var grantedRoots: [URL] = []
    private(set) var isScanning = false

    /// Pulls security-scoped bookmarks from disk and runs an initial scan.
    func bootstrap() {
        grantedRoots = BookmarkStore.shared.resolveStoredRoots()
        globalSettings = GlobalSettingsLoader.load()
        refresh()
    }

    /// Re-scans the current granted roots from scratch.
    func refresh() {
        isScanning = true
        let roots = grantedRoots
        Task.detached(priority: .userInitiated) {
            let directories = DirectoryScanner.scan(roots: roots)
            await MainActor.run {
                self.directories = directories
                self.isScanning = false
            }
        }
    }

    /// Lets the user choose a new directory to scan and re-runs the scan.
    func addRoot() {
        guard let url = BookmarkStore.shared.addRoot() else { return }
        grantedRoots.append(url)
        refresh()
    }

    /// Removes a previously-granted root.
    func removeRoot(_ url: URL) {
        BookmarkStore.shared.removeRoot(url)
        grantedRoots.removeAll { $0 == url }
        refresh()
    }

    /// Flips the enabled state of a plugin in the directory's `settings.local.json` and persists it.
    func togglePlugin(in directory: ClaudeDirectory, identifier: String, enabled: Bool) {
        mutateLocal(directory) { file in
            file.setPlugin(identifier, enabled: enabled)
        }
    }

    /// Clears a per-directory plugin override so the global value applies again.
    func clearPluginOverride(in directory: ClaudeDirectory, identifier: String) {
        mutateLocal(directory) { file in
            file.setPlugin(identifier, enabled: nil)
        }
    }

    /// Flips the enabled state of an MCP server in the directory's `settings.local.json`.
    func toggleMcpServer(in directory: ClaudeDirectory, name: String, enabled: Bool) {
        mutateLocal(directory) { file in
            file.setMcpServerEnabled(name, enabled: enabled)
        }
    }

    // MARK: - Private

    private func mutateLocal(_ directory: ClaudeDirectory, _ mutate: (inout ClaudeSettingsFile) -> Void) {
        let dotClaude = directory.url.appendingPathComponent(".claude")
        let localURL = dotClaude.appendingPathComponent(ClaudeSettingsScope.local.fileName)
        var file = directory.local ?? ClaudeSettingsFile(url: localURL, scope: .local)
        mutate(&file)
        do {
            try SettingsFileIO.save(file)
            updateLocal(file, for: directory)
        } catch {
            NSLog("Failed to save \(localURL.path): \(error)")
        }
    }

    private func updateLocal(_ file: ClaudeSettingsFile, for directory: ClaudeDirectory) {
        guard let index = directories.firstIndex(of: directory) else { return }
        directories[index].local = file
    }
}
