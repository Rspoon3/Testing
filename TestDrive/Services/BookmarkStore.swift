//
//  BookmarkStore.swift
//  TestDrive
//

import Foundation
import AppKit

/// Persists security-scoped bookmarks for the directory roots the user has granted access to.
///
/// The sandbox forbids reading arbitrary paths, so the user must pick each root with `NSOpenPanel`.
/// We persist the resulting bookmarks in `UserDefaults` and resolve them on launch.
@MainActor
final class BookmarkStore {
    static let shared = BookmarkStore()

    private let defaultsKey = "ClaudePluginToggler.RootBookmarks"
    private var activeURLs: [URL] = []

    private init() {}

    // MARK: - Public

    /// Prompts the user to choose a directory and persists a security-scoped bookmark for it.
    /// Returns the resolved URL on success.
    @discardableResult
    func addRoot() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Pick a directory that contains projects with .claude folders."
        panel.prompt = "Add Root"

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        appendBookmark(for: url)
        activeURLs.append(url)
        return url
    }

    /// Resolves all stored bookmarks. Must be called before scanning. Each returned URL has
    /// already had `startAccessingSecurityScopedResource()` called on it; the store keeps
    /// access alive for its lifetime.
    func resolveStoredRoots() -> [URL] {
        guard let data = UserDefaults.standard.array(forKey: defaultsKey) as? [Data] else { return [] }

        var resolved: [URL] = []
        var refreshed: [Data] = []
        for bookmark in data {
            var isStale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: bookmark,
                    options: [.withSecurityScope],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                guard url.startAccessingSecurityScopedResource() else { continue }
                if isStale {
                    if let fresh = try? url.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    ) {
                        refreshed.append(fresh)
                    } else {
                        refreshed.append(bookmark)
                    }
                } else {
                    refreshed.append(bookmark)
                }
                resolved.append(url)
            } catch {
                continue
            }
        }
        if refreshed != data {
            UserDefaults.standard.set(refreshed, forKey: defaultsKey)
        }
        activeURLs = resolved
        return resolved
    }

    /// Removes a previously-granted root by URL.
    func removeRoot(_ url: URL) {
        activeURLs.removeAll { $0 == url }
        url.stopAccessingSecurityScopedResource()

        guard let data = UserDefaults.standard.array(forKey: defaultsKey) as? [Data] else { return }
        let filtered = data.filter { bookmark in
            var isStale = false
            guard let resolved = try? URL(
                resolvingBookmarkData: bookmark,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) else { return true }
            return resolved != url
        }
        UserDefaults.standard.set(filtered, forKey: defaultsKey)
    }

    // MARK: - Private

    private func appendBookmark(for url: URL) {
        guard let data = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        var existing = (UserDefaults.standard.array(forKey: defaultsKey) as? [Data]) ?? []
        existing.append(data)
        UserDefaults.standard.set(existing, forKey: defaultsKey)
    }
}
