import Foundation

/// A section of items grouped by a shared identifier.
struct FetchSection<SectionID: Hashable & Sendable, Item: Sendable>: Identifiable, Sendable {
    let id: SectionID
    var items: [Item] = []
}
