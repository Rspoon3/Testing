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
    public static var _columnWidth: Int { 1 }

    public func encode(to encoder: inout any StructuredQueriesCore.RowEncoder) throws {
        try rawValue.encode(to: &encoder)
    }

    public init(from decoder: inout any StructuredQueriesCore.RowDecoder) throws {
        let rawValue = try String(from: &decoder)
        guard let value = SharePermission(rawValue: rawValue) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid SharePermission rawValue: \(rawValue)"
                )
            )
        }
        self = value
    }
}
