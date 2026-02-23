import Foundation

/// Filesystem paths for the envelope sample.
enum EnvelopePaths {
    /// Returns the default persistent database URL for the demo app.
    static func defaultDatabaseURL(fileManager: FileManager = .default) throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = appSupport
            .appendingPathComponent("TestDrive", isDirectory: true)
            .appendingPathComponent("EnvelopeEncryption", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("envelope.sqlite")
    }

    /// Returns a unique persistent test database URL in temporary storage.
    static func temporaryDatabaseURL(testName: String, fileManager: FileManager = .default) throws -> URL {
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("TestDrive", isDirectory: true)
            .appendingPathComponent("EnvelopeEncryptionTests", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(testName)-\(UUID().uuidString).sqlite")
    }
}
