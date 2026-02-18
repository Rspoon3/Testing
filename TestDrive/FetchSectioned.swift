import GRDB
import SQLiteData
import StructuredQueriesCore
import SwiftUI

// MARK: - QueryCursor + sectioned

extension QueryCursor {
    /// Groups pre-sorted cursor rows into sections in a single O(n) pass.
    func sectioned<SectionID: Hashable & Sendable>(
        by sectionedBy: (Element) -> SectionID
    ) throws -> [FetchSection<SectionID, Element>] where Element: Sendable {
        var sections: [FetchSection<SectionID, Element>] = []
        var currentID: SectionID?
        while let row = try next() {
            let id = sectionedBy(row)
            if id == currentID {
                sections[sections.count - 1].items.append(row)
            } else {
                sections.append(FetchSection(id: id, items: [row]))
                currentID = id
            }
        }
        return sections
    }
}

// MARK: - SelectStatement + sectioned

extension SelectStatement where Joins == (), QueryValue == () {
    /// Groups pre-sorted rows into sections by a key path.
    ///
    /// The query must include `.order` with the section field first
    /// so that rows with the same value are contiguous.
    ///
    /// ```swift
    /// @Fetch(
    ///     Book.order { $0.genre.asc() }
    ///         .sectioned(by: \.genre)
    /// ) var sections: [FetchSection<String, Book>] = []
    /// ```
    nonisolated func sectioned<SectionID: Hashable & Sendable>(
        by keyPath: KeyPath<From.QueryOutput, SectionID>
    ) -> SectionedRequest<SectionID, From.QueryOutput> where From.QueryOutput: Sendable {
        SectionedRequest(self, sectionedBy: { $0[keyPath: keyPath] })
    }
}

// MARK: - SectionedRequest

/// A fetch request that streams rows from SQLite via a cursor and groups
/// them into sections in a single O(n) pass. No intermediate array
/// allocation, no client-side sorting — SQLite handles ORDER BY.
struct SectionedRequest<SectionID: Hashable & Sendable, Record: Sendable>: FetchKeyRequest {
    private let _fetchCursor: @Sendable (Database) throws -> QueryCursor<Record>
    private let sectionedBy: @Sendable (Record) -> SectionID

    init<S: SelectStatement>(
        _ statement: S,
        sectionedBy: @escaping @Sendable (Record) -> SectionID
    ) where S.From.QueryOutput == Record, S.Joins == (), S.QueryValue == () {
        self._fetchCursor = { db in try statement.fetchCursor(db) }
        self.sectionedBy = sectionedBy
    }

    func fetch(_ db: Database) throws -> [FetchSection<SectionID, Record>] {
        try _fetchCursor(db).sectioned(by: sectionedBy)
    }

    // MARK: - Hashable

    static func == (lhs: Self, rhs: Self) -> Bool { true }

    func hash(into hasher: inout Hasher) {}
}
