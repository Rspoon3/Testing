//
//  MultiItemReorderRepro.swift
//  TestDrive
//
//  Minimal repro for FitCard's "Data" tab tile grid: a single combined
//  ForEach where selected tiles lead in order and can be drag-reordered,
//  and unselected tiles can be dragged into the selected zone. iOS lets
//  you long-press one tile then tap additional ones to stack them into
//  the same drag session, but in testing `ReorderDifference.sources`
//  only ever reports one item for that gesture — this view isolates that
//  down to nothing but the API itself, so on-screen logging can confirm
//  whether it's a beta bug or something FitCard-specific.
//

import SwiftUI

nonisolated private struct ReproItem: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
}

private let allItems: [ReproItem] = (1...12).map { ReproItem(id: "item-\($0)", label: "Item \($0)") }

struct MultiItemReorderRepro: View {
    @State private var selectedIDs: [String] = ["item-1", "item-2", "item-3"]
    @State private var log: [String] = []

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                grid
                    .padding()
                Divider()
                logList
            }
            .navigationTitle("Multi-Item Reorder Repro")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear Log") { log.removeAll() }
                }
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var grid: some View {
        if #available(iOS 27, *) {
            reorderableGrid
        } else {
            Text("Requires iOS 27")
        }
    }

    @available(iOS 27, *)
    private var reorderableGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(orderedItems) { item in
                tile(item)
            }
            .reorderable()
        }
        .reorderContainer(for: ReproItem.self) { difference in
            handle(difference)
        }
        .animation(.default, value: selectedIDs)
    }

    private func tile(_ item: ReproItem) -> some View {
        let isSelected = selectedIDs.contains(item.id)

        return Button {
            toggle(item)
        } label: {
            Text(item.label)
                .font(.caption)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var logList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

    // MARK: - Private Helpers

    private var orderedItems: [ReproItem] {
        let selected = selectedIDs.compactMap { id in allItems.first { $0.id == id } }
        let unselected = allItems.filter { !selectedIDs.contains($0.id) }
        return selected + unselected
    }

    private func toggle(_ item: ReproItem) {
        if let index = selectedIDs.firstIndex(of: item.id) {
            selectedIDs.remove(at: index)
        } else {
            selectedIDs.append(item.id)
        }
    }

    @available(iOS 27, *)
    private func handle(_ difference: ReorderDifference<ReproItem.ID, ReorderableSingleCollectionIdentifier>) {
        let positionDescription: String
        switch difference.destination.position {
        case .end: positionDescription = "end"
        case .before(let targetID): positionDescription = "before(\(targetID))"
        }
        let line = "sources=[\(difference.sources.joined(separator: ", "))] position=\(positionDescription) selectedBefore=[\(selectedIDs.joined(separator: ", "))]"
        log.append(line)

        let sourceIDs = difference.sources
        guard !sourceIDs.isEmpty else { return }
        let sourceSet = Set(sourceIDs)

        let combinedIDs = orderedItems.map(\.id)
        let targetIndex: Int
        switch difference.destination.position {
        case .end:
            targetIndex = combinedIDs.count
        case .before(let targetID):
            targetIndex = combinedIDs.firstIndex(of: targetID) ?? combinedIDs.count
        }

        var ids = selectedIDs
        let alreadySelected = ids.filter(sourceSet.contains)
        ids.removeAll { sourceSet.contains($0) }

        guard targetIndex <= selectedIDs.count else {
            if !alreadySelected.isEmpty {
                selectedIDs = ids
            }
            return
        }

        let insertionIndex = selectedIDs.prefix(targetIndex).filter { !sourceSet.contains($0) }.count
        ids.insert(contentsOf: sourceIDs, at: min(insertionIndex, ids.count))
        selectedIDs = ids
    }
}

#Preview {
    MultiItemReorderRepro()
}
