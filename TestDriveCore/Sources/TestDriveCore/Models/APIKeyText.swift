import Foundation
import SQLiteData

/// FTS5 virtual table for full-text search of API keys.
///
/// This table mirrors searchable text fields from the APIKey table
/// and enables efficient full-text search with ranking.
@Table
public struct APIKeyText: FTS5 {
    /// Row ID linking to the APIKey table.
    public let rowid: Int

    /// Searchable: API key label.
    public let label: String

    /// Searchable: Website domain.
    public let websiteDomain: String

    /// Searchable: Company name.
    public let company: String

    /// Searchable: User notes.
    public let notes: String
}

extension APIKeyText.TableColumns {
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
