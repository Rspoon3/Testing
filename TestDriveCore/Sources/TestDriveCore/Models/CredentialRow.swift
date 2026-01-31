import Foundation
import SQLiteData

/// A row combining a credential with its local preferences.
///
/// Used for efficiently fetching credentials with their pin state in a single query.
@Selection
public struct CredentialRow: Sendable, Equatable {
    /// The credential.
    public let credential: Credential

    /// Whether this credential is pinned.
    public let isPinned: Bool

    // MARK: - Initializer

    /// Creates a new credential row.
    ///
    /// - Parameters:
    ///   - credential: The credential.
    ///   - isPinned: Whether the credential is pinned.
    public init(credential: Credential, isPinned: Bool) {
        self.credential = credential
        self.isPinned = isPinned
    }
}
