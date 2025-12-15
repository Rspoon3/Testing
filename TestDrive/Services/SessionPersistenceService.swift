//
//  SessionPersistenceService.swift
//  TestDrive
//

import Foundation

/// Errors that can occur during session persistence operations.
enum SessionPersistenceError: LocalizedError {
    case directoryCreationFailed(Error)
    case encodingFailed(Error)
    case decodingFailed(Error)
    case fileNotFound
    case writeFailed(Error)
    case readFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let error):
            return "Failed to create sessions directory: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode session: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode session: \(error.localizedDescription)"
        case .fileNotFound:
            return "Session file not found"
        case .writeFailed(let error):
            return "Failed to write session: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read session: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete session: \(error.localizedDescription)"
        }
    }
}

/// Manages saving and loading ranking sessions to JSON files.
actor SessionPersistenceService {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Directory for storing session files.
    private var sessionsDirectory: URL {
        get throws {
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            return appSupport.appendingPathComponent("Sessions", isDirectory: true)
        }
    }

    // MARK: - Initializer

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = .prettyPrinted
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Public Helpers

    /// Saves a session to disk.
    /// - Parameter session: The session to save.
    func save(_ session: RankingSession) async throws {
        let directory = try sessionsDirectory
        try createDirectoryIfNeeded(at: directory)

        let fileURL = directory.appendingPathComponent("\(session.id.uuidString).json")

        do {
            let data = try encoder.encode(session)
            try data.write(to: fileURL, options: .atomic)
        } catch let error as EncodingError {
            throw SessionPersistenceError.encodingFailed(error)
        } catch {
            throw SessionPersistenceError.writeFailed(error)
        }
    }

    /// Loads a session by ID.
    /// - Parameter id: The session UUID.
    /// - Returns: The loaded session.
    func load(id: UUID) async throws -> RankingSession {
        let directory = try sessionsDirectory
        let fileURL = directory.appendingPathComponent("\(id.uuidString).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw SessionPersistenceError.fileNotFound
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(RankingSession.self, from: data)
        } catch let error as DecodingError {
            throw SessionPersistenceError.decodingFailed(error)
        } catch {
            throw SessionPersistenceError.readFailed(error)
        }
    }

    /// Loads all saved sessions.
    /// - Returns: Array of all sessions sorted by last modified date (newest first).
    func loadAllSessions() async throws -> [RankingSession] {
        let directory = try sessionsDirectory

        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        let fileURLs = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ).filter { $0.pathExtension == "json" }

        var sessions: [RankingSession] = []

        for fileURL in fileURLs {
            do {
                let data = try Data(contentsOf: fileURL)
                let session = try decoder.decode(RankingSession.self, from: data)
                sessions.append(session)
            } catch {
                // Skip corrupted files
                continue
            }
        }

        // Sort by last modified date, newest first
        return sessions.sorted { $0.lastModified > $1.lastModified }
    }

    /// Deletes a session.
    /// - Parameter id: The session UUID to delete.
    func delete(id: UUID) async throws {
        let directory = try sessionsDirectory
        let fileURL = directory.appendingPathComponent("\(id.uuidString).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return // Already deleted
        }

        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw SessionPersistenceError.deleteFailed(error)
        }
    }

    /// Updates an existing session (called after each comparison).
    /// - Parameter session: The updated session.
    func update(_ session: RankingSession) async throws {
        var updatedSession = session
        updatedSession.lastModified = Date()
        try await save(updatedSession)
    }

    // MARK: - Private Helpers

    private func createDirectoryIfNeeded(at url: URL) throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }

        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw SessionPersistenceError.directoryCreationFailed(error)
        }
    }
}
