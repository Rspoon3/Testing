import Foundation
import GRDB
import SQLiteData
import StructuredQueriesCore
import SwiftUI

// MARK: - SortDescriptor

/// A sort descriptor that works with any `Comparable` property.
///
/// Foundation's `SortDescriptor` does not support `Bool` on non-NSObject types.
/// This type fills that gap for `@Table` structs.
nonisolated struct SortDescriptor<Compared>: Hashable, Sendable {
    private nonisolated(unsafe) let keyPath: PartialKeyPath<Compared>
    private let _compare: @Sendable (Compared, Compared) -> ComparisonResult
    let order: SortOrder

    init<Value: Comparable>(
        _ keyPath: KeyPath<Compared, Value>,
        order: SortOrder = .forward
    ) {
        self.keyPath = keyPath
        self.order = order
        self._compare = { lhs, rhs in
            let l = lhs[keyPath: keyPath]
            let r = rhs[keyPath: keyPath]
            if l < r { return .orderedAscending }
            if l > r { return .orderedDescending }
            return .orderedSame
        }
    }

    /// Bool-specific overload since `Bool` does not conform to `Comparable`.
    init(
        _ keyPath: KeyPath<Compared, Bool>,
        order: SortOrder = .forward
    ) {
        self.keyPath = keyPath
        self.order = order
        self._compare = { lhs, rhs in
            let l = lhs[keyPath: keyPath]
            let r = rhs[keyPath: keyPath]
            if l == r { return .orderedSame }
            return l ? .orderedDescending : .orderedAscending
        }
    }

    func compare(_ lhs: Compared, _ rhs: Compared) -> ComparisonResult {
        let result = _compare(lhs, rhs)
        if order == .reverse {
            switch result {
            case .orderedAscending: return .orderedDescending
            case .orderedDescending: return .orderedAscending
            case .orderedSame: return .orderedSame
            }
        }
        return result
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.keyPath == rhs.keyPath && lhs.order == rhs.order
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(keyPath)
        hasher.combine(order)
    }
}

extension Array {
    /// Sorts the array using an array of `SortDescriptor`s.
    func sorted(using descriptors: [SortDescriptor<Element>]) -> [Element] {
        guard !descriptors.isEmpty else { return self }
        return sorted { lhs, rhs in
            for descriptor in descriptors {
                switch descriptor.compare(lhs, rhs) {
                case .orderedAscending: return true
                case .orderedDescending: return false
                case .orderedSame: continue
                }
            }
            return false
        }
    }
}

// MARK: - FetchSectioned

/// A property wrapper that fetches rows from SQLite, sorts them using
/// `SortDescriptor`, and groups them into sections by a key path.
///
/// SQL handles the fetch; `SortDescriptor` guarantees final ordering
/// (O(n) on pre-sorted data via TimSort); a single linear pass groups
/// consecutive rows into `FetchSection` values.
///
/// ```swift
/// @FetchSectioned(
///     Book.all,
///     sectionIdentifier: \.genre,
///     sortDescriptors: [
///         SortDescriptor(\.genre, order: .forward),
///         SortDescriptor(\.title, order: .forward),
///     ]
/// )
/// var sections: [FetchSection<String, Book>]
/// ```
@propertyWrapper
struct FetchSectioned<SectionID: Hashable & Sendable, Record: Sendable>: DynamicProperty {
    @Fetch private var sections: [FetchSection<SectionID, Record>]

    var wrappedValue: [FetchSection<SectionID, Record>] { sections }

    init<S: SelectStatement>(
        _ statement: S,
        sectionIdentifier: KeyPath<Record, SectionID>,
        sortDescriptors: [SortDescriptor<Record>]
    ) where S.From.QueryOutput == Record, S.Joins == (), S.QueryValue == () {
        let request = SectionedRequest(
            statement,
            sectionIdentifier: sectionIdentifier,
            sortDescriptors: sortDescriptors
        )
        _sections = Fetch(wrappedValue: [], request)
    }

    init<S: SelectStatement>(
        _ statement: S,
        sectionIdentifier: KeyPath<Record, SectionID>,
        sortDescriptors: [SortDescriptor<Record>],
        animation: Animation
    ) where S.From.QueryOutput == Record, S.Joins == (), S.QueryValue == () {
        let request = SectionedRequest(
            statement,
            sectionIdentifier: sectionIdentifier,
            sortDescriptors: sortDescriptors
        )
        _sections = Fetch(wrappedValue: [], request, animation: animation)
    }
}

// MARK: - SectionedRequest

/// A fetch request that retrieves rows from SQLite, sorts using
/// `SortDescriptor`, and groups into sections in a single O(n) pass.
struct SectionedRequest<SectionID: Hashable & Sendable, Record: Sendable>: FetchKeyRequest {
    private let _fetch: @Sendable (Database) throws -> [Record]
    private nonisolated(unsafe) let sectionIdentifier: KeyPath<Record, SectionID>
    private let sortDescriptors: [SortDescriptor<Record>]

    init<S: SelectStatement>(
        _ statement: S,
        sectionIdentifier: KeyPath<Record, SectionID>,
        sortDescriptors: [SortDescriptor<Record>]
    ) where S.From.QueryOutput == Record, S.Joins == (), S.QueryValue == () {
        self._fetch = { db in try statement.fetchAll(db) }
        self.sectionIdentifier = sectionIdentifier
        self.sortDescriptors = sortDescriptors
    }

    func fetch(_ db: Database) throws -> [FetchSection<SectionID, Record>] {
        let rows = try _fetch(db).sorted(using: sortDescriptors)
        var sections: [FetchSection<SectionID, Record>] = []
        var currentID: SectionID?
        for row in rows {
            let id = row[keyPath: sectionIdentifier]
            if id == currentID {
                sections[sections.count - 1].items.append(row)
            } else {
                sections.append(FetchSection(id: id, items: [row]))
                currentID = id
            }
        }
        return sections
    }

    // MARK: - Hashable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.sortDescriptors == rhs.sortDescriptors
            && lhs.sectionIdentifier == rhs.sectionIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(sortDescriptors)
        hasher.combine(sectionIdentifier)
    }
}
