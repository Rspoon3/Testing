import Foundation
import SQLiteData

/// A row combining an credential with its local preferences.
///
/// Used for efficiently fetching credentials with their pin state in a single query.
@Selection
public struct CredentialRow: Sendable, Equatable {
    /// The credential.
    public let apiKey: Credential

    /// Whether this credential is pinned.
    public let isPinned: Bool

    // MARK: - Initializer

    /// Creates a new credential row.
    ///
    /// - Parameters:
    ///   - apiKey: The credential.
    ///   - isPinned: Whether the credential is pinned.
    public init(apiKey: Credential, isPinned: Bool) {
        self.apiKey = apiKey
        self.isPinned = isPinned
    }
}
