import Foundation
import StructuredQueriesCore

/// Represents the permission level for a vault participant.
///
/// Defines what actions a participant can perform within a shared vault.
public enum SharePermission: String, Codable, Sendable {
    /// Owner has full control including sharing and deletion.
    case owner

    /// Read-write permission allows viewing and modifying keys.
    case readWrite

    /// Read-only permission allows viewing keys only.
    case readOnly
}

// MARK: - QueryRepresentable Conformance

extension SharePermission: QueryRepresentable {
    public typealias QueryOutput = Self

    public static var _columnWidth: Int { 1 }

    public init(queryOutput: Self) {
        self = queryOutput
    }

    public var queryOutput: Self {
        self
    }
}
