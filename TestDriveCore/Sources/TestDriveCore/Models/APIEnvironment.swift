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
    public typealias QueryOutput = Self

    public static var _columnWidth: Int { 1 }

    public init(queryOutput: Self) {
        self = queryOutput
    }

    public var queryOutput: Self {
        self
    }
}
