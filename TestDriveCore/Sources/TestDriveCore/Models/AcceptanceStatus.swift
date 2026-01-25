import Foundation
import StructuredQueriesCore

/// Represents the status of a vault share invitation.
///
/// Tracks whether a participant has accepted, declined, or is still pending
/// response to a vault share invitation.
public enum AcceptanceStatus: String, Codable, Sendable {
    /// Share invitation is pending acceptance.
    case pending

    /// Share invitation has been accepted.
    case accepted

    /// Share invitation has been declined.
    case declined
}

// MARK: - QueryRepresentable Conformance

extension AcceptanceStatus: QueryRepresentable {
    public static var _columnWidth: Int { 1 }

    public func encode(to encoder: inout any StructuredQueriesCore.RowEncoder) throws {
        try rawValue.encode(to: &encoder)
    }

    public init(from decoder: inout any StructuredQueriesCore.RowDecoder) throws {
        let rawValue = try String(from: &decoder)
        guard let value = AcceptanceStatus(rawValue: rawValue) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid AcceptanceStatus rawValue: \(rawValue)"
                )
            )
        }
        self = value
    }
}
