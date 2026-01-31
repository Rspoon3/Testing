import Foundation
import SQLiteData

/// FTS5 virtual table for full-text search of credentials.
///
/// This table mirrors searchable text fields from the Credential table
/// and enables efficient full-text search with ranking.
@Table
public struct CredentialText: FTS5 {
    /// Row ID linking to the Credential table.
    public let rowid: Int

    /// Searchable: credential label.
    public let label: String

    /// Searchable: Website domain.
    public let websiteDomain: String

    /// Searchable: Company name.
    public let company: String

    /// Searchable: User notes.
    public let notes: String
}

extension CredentialText.TableColumns {
    /// Default BM25 ranking with weighted columns.
    ///
    /// - label: 10x weight (most important)
    /// - websiteDomain: 5x weight
    /// - company: 5x weight
    /// - notes: 1x weight (default)
    public var defaultRank: some QueryExpression<Double> {
        bm25([\.label: 10, \.websiteDomain: 5, \.company: 5])
    }
}
