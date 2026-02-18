import Foundation

/// A section of items grouped by a shared identifier.
struct FetchSection<SectionID: Hashable & Sendable, Item: Sendable>: Identifiable, Sendable {
    let id: SectionID
    var items: [Item] = []
}

extension FetchSection {
    /// Groups a sorted array of items into sections based on a key path.
    ///
    /// Items must already be sorted so that items with the same section
    /// identifier are contiguous. Use `SortDescriptor` on the section
    /// field first to guarantee this.
    static func sections(
        from items: [Item],
        by sectionIdentifier: KeyPath<Item, SectionID>
    ) -> [FetchSection] {
        var sections: [FetchSection] = []
        var currentID: SectionID?
        for item in items {
            let id = item[keyPath: sectionIdentifier]
            if id == currentID {
                sections[sections.count - 1].items.append(item)
            } else {
                sections.append(FetchSection(id: id, items: [item]))
                currentID = id
            }
        }
        return sections
    }
}
