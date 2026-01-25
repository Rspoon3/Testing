import Foundation
import StructuredQueriesCore

/// Represents the environment type for an API key.
///
/// Use this enum to categorize API keys based on their deployment environment,
/// helping organize keys by their intended use case.
public enum APIEnvironment: String, Codable, CaseIterable, Sendable {
    /// Production environment for live systems.
    case production

    /// Staging environment for pre-production testing.
    case staging

    /// Development environment for active development.
    case development

    /// Testing environment for automated tests.
    case testing

    /// Custom environment for specialized use cases.
    case custom
}

// MARK: - QueryRepresentable Conformance

extension APIEnvironment: QueryRepresentable {
    public static var _columnWidth: Int { 1 }

    public func encode(to encoder: inout any StructuredQueriesCore.RowEncoder) throws {
        try rawValue.encode(to: &encoder)
    }

    public init(from decoder: inout any StructuredQueriesCore.RowDecoder) throws {
        let rawValue = try String(from: &decoder)
        guard let value = APIEnvironment(rawValue: rawValue) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid APIEnvironment rawValue: \(rawValue)"
                )
            )
        }
        self = value
    }
}
