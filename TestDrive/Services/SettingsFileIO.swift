//
//  SettingsFileIO.swift
//  TestDrive
//

import Foundation

/// Reads and writes `ClaudeSettingsFile` instances on disk, preserving JSON formatting.
enum SettingsFileIO {
    enum Failure: Error {
        case decodeFailed(URL, Error)
        case encodeFailed(URL, Error)
    }

    /// Loads the settings file at `url`, or returns `nil` when the file does not exist.
    static func load(url: URL, scope: ClaudeSettingsScope) throws -> ClaudeSettingsFile? {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return nil
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw Failure.decodeFailed(url, error)
        }
        let root: JSONValue
        do {
            root = try JSONDecoder().decode(JSONValue.self, from: data)
        } catch {
            throw Failure.decodeFailed(url, error)
        }
        return ClaudeSettingsFile(url: url, scope: scope, root: root)
    }

    /// Writes the settings file to disk using sorted, pretty-printed JSON with tab indentation.
    static func save(_ file: ClaudeSettingsFile) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data: Data
        do {
            data = try encoder.encode(file.root)
        } catch {
            throw Failure.encodeFailed(file.url, error)
        }
        do {
            try FileManager.default.createDirectory(
                at: file.url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: file.url, options: .atomic)
        } catch {
            throw Failure.encodeFailed(file.url, error)
        }
    }
}
