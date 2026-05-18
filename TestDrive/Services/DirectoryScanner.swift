//
//  DirectoryScanner.swift
//  TestDrive
//

import Foundation

/// Walks granted roots looking for `.claude` directories and loads their settings files.
enum DirectoryScanner {
    /// How deep to recurse from each root.
    static let maxDepth = 5

    /// Directory names skipped during traversal to avoid wandering into noisy caches.
    /// `.claude` is *not* in this list — that's the thing we're looking for.
    private static let skippedDirectories: Set<String> = [
        ".git",
        ".build",
        ".swiftpm",
        "node_modules",
        "Pods",
        "DerivedData",
        "build",
        "target",
        "dist",
        ".next",
        ".venv",
        "__pycache__",
    ]

    /// Returns every `ClaudeDirectory` found beneath `roots`, sorted by display name.
    static func scan(roots: [URL]) -> [ClaudeDirectory] {
        var seen: Set<URL> = []
        var results: [ClaudeDirectory] = []

        for root in roots {
            for url in claudeFolders(under: root) {
                guard seen.insert(url).inserted else { continue }
                let parent = url.deletingLastPathComponent()
                let shared = try? SettingsFileIO.load(
                    url: url.appendingPathComponent("settings.json"),
                    scope: .shared
                )
                let local = try? SettingsFileIO.load(
                    url: url.appendingPathComponent("settings.local.json"),
                    scope: .local
                )
                results.append(ClaudeDirectory(url: parent, shared: shared, local: local))
            }
        }

        return results.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    // MARK: - Private

    private static func claudeFolders(under root: URL) -> [URL] {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey]
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [],
            errorHandler: { _, _ in true }
        ) else { return [] }

        var found: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            // Cap recursion depth so we don't wander into deeply nested SPM caches.
            let depth = url.pathComponents.count - root.pathComponents.count
            if depth > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            guard
                let values = try? url.resourceValues(forKeys: Set(keys)),
                values.isDirectory == true
            else { continue }

            if url.lastPathComponent == ".claude" {
                found.append(url)
                enumerator.skipDescendants()
                continue
            }

            if Self.skippedDirectories.contains(url.lastPathComponent) {
                enumerator.skipDescendants()
            }
        }
        return found
    }
}
