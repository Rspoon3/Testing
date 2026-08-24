import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

// The BY-THE-BOOK iOS 27 drag-and-drop setup, exactly as Apple's documentation and the WWDC26
// "Build powerful drag and drop in SwiftUI" code-along prescribe, in a realistic iPad shape:
// a `NavigationSplitView` whose sidebar rows are drop targets and whose detail column shows
// draggable item cards.
//
//   Drag side:  .draggable(containerItemID:) + .dragContainer(for:) +
//               .dragConfiguration(DragConfiguration(allowMove: true))
//   Drop side:  .dropDestination(for:isEnabled:action:) (the ([T], DropSession) -> Void overload)
//               + .dropConfiguration { session in ... } returning .move / .forbidden
//
// KNOWN BUG (iOS 27.0, verified 24A5408d): while `.dropConfiguration` is attached to a drop
// target that is a `List` ROW, drops are NEVER delivered — the hover closure runs and returns
// `.move`, yet the dropDestination action never fires and the preview snaps back. The IDENTICAL
// modifiers on a plain view (the rounded "drop boxes" in the detail column below) work
// perfectly, including the `.forbidden` same-list suppression. Apple's own WWDC26 sample
// (MakingACardGameWithDragDropAndReorderingInSwiftUI) only ever attaches `.dropConfiguration`
// to non-List views (a ZStack and an HStack) — it never exercises the List-row case that
// breaks. This file keeps both target kinds side by side as a demonstration; the "Workaround"
// tab shows the isEnabled-based approach that works for List rows today.

// MARK: - Model

struct DemoItem: Codable, Hashable, Identifiable, Transferable {
    struct ID: Codable, Hashable, Sendable {
        let itemID: UUID
        let listID: UUID
    }

    let itemID: UUID
    let listID: UUID
    let name: String

    var id: ID { ID(itemID: itemID, listID: listID) }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

struct DemoList: Identifiable, Hashable {
    let id: UUID
    let name: String
    let symbol: String
}

@MainActor
@Observable
final class DemoModel {
    let lists: [DemoList]
    var items: [DemoItem]
    var log: [String] = []

    init() {
        let groceries = DemoList(id: UUID(), name: "Groceries", symbol: "cart")
        let favorites = DemoList(id: UUID(), name: "Favorites", symbol: "star")
        let archive = DemoList(id: UUID(), name: "Archive", symbol: "archivebox")
        lists = [groceries, favorites, archive]
        items = ["Apples", "Bananas", "Cherries", "Dates", "Elderberries", "Figs"].map {
            DemoItem(itemID: UUID(), listID: groceries.id, name: $0)
        }
    }

    func listName(_ id: UUID) -> String {
        lists.first(where: { $0.id == id })?.name ?? "?"
    }

    func items(in listID: UUID) -> [DemoItem] {
        items.filter { $0.listID == listID }
    }

    func items(withIDs ids: [DemoItem.ID]) -> [DemoItem] {
        ids.compactMap { id in items.first { $0.itemID == id.itemID } }
    }

    func receive(_ dropped: [DemoItem], into listID: UUID, via target: String) {
        note("\(target): \(dropped.map(\.name).joined(separator: ", ")) -> \(listName(listID))")
        for item in dropped {
            guard let index = items.firstIndex(where: { $0.itemID == item.itemID }) else { continue }
            items[index] = DemoItem(itemID: item.itemID, listID: listID, name: item.name)
        }
    }

    func note(_ message: String) {
        log.append(message)
    }
}

// MARK: - View

struct IntendedDropConfigurationDemoView: View {
    @State private var model = DemoModel()
    @State private var selectedListID: UUID?

    var body: some View {
        NavigationSplitView {
            List(model.lists, selection: $selectedListID) { list in
                sidebarRow(for: list)
                    .tag(list.id)
            }
            .navigationTitle("Lists")
        } detail: {
            if let selectedListID {
                detailColumn(for: selectedListID)
            } else {
                ContentUnavailableView(
                    "Select a list",
                    systemImage: "sidebar.left",
                    description: Text("Then drag its items onto another list in the sidebar.")
                )
            }
        }
        .onAppear {
            if selectedListID == nil {
                selectedListID = model.lists.first?.id
            }
        }
    }

    // MARK: Sidebar (drop side — the intended APIs)

    private func sidebarRow(for list: DemoList) -> some View {
        Label {
            HStack {
                Text(list.name)
                Spacer()
                Text("\(model.items(in: list.id).count)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } icon: {
            Image(systemName: list.symbol)
        }
        // The session-based drop destination, per the WWDC26 code-along.
        .dropDestination(for: DemoItem.self) { items, _ in
            model.receive(items, into: list.id, via: "listRow")
        }
        // Apple's intended hover-time validation: return .forbidden to reject a drop of a list's
        // own items back onto itself, .move otherwise. See `dropBox(for:)` — identical modifiers
        // on a plain (non-List) view — for isolating whether List rows are what break this.
        .dropConfiguration { session in
            dropConfiguration(for: session, list: list)
        }
    }

    private nonisolated func dropConfiguration(for session: DropSession, list: DemoList) -> DropConfiguration {
        let draggedIDs = session.localSession?.draggedItemIDs(for: DemoItem.ID.self) ?? []
        if draggedIDs.contains(where: { $0.listID == list.id }) {
            return DropConfiguration(operation: .forbidden)
        }
        if session.suggestedOperations.contains(.move) {
            return DropConfiguration(operation: .move)
        }
        return DropConfiguration(operation: .copy)
    }

    /// The same drop destination + configuration as `sidebarRow(for:)`, but on a plain rounded
    /// rectangle instead of a `List` row — mirroring the WWDC26 sample's `DestinationView`
    /// (a `ZStack`, not a `List`), which uses this exact modifier pairing. If drops land here
    /// but not on the sidebar rows, `.dropConfiguration` is broken specifically for `List`-row
    /// drop targets rather than everywhere.
    private func dropBox(for list: DemoList) -> some View {
        VStack(spacing: 6) {
            Image(systemName: list.symbol)
            Text(list.name)
                .font(.caption)
            Text("\(model.items(in: list.id).count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(width: 110, height: 84)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        .dropDestination(for: DemoItem.self) { items, _ in
            model.receive(items, into: list.id, via: "plainBox")
        }
        .dropConfiguration { session in
            dropConfiguration(for: session, list: list)
        }
    }

    // MARK: Detail (drag side)

    private func detailColumn(for listID: UUID) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(
                "Intended iOS 27 API: dropDestination + dropConfiguration, on two target kinds with identical modifiers. The plain boxes below accept drops (and forbid same-list ones); the sidebar List rows never deliver a drop while dropConfiguration is attached.",
                systemImage: "exclamationmark.triangle"
            )
            .font(.callout)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(model.lists) { list in
                    dropBox(for: list)
                }
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(model.items(in: listID), id: \.itemID) { item in
                        VStack(spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                            Text(model.listName(item.listID))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 150, height: 90)
                        .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        .draggable(containerItemID: item.id)
                    }
                }
            }
            .dragContainer(for: DemoItem.self) { ids in
                model.items(withIDs: ids)
            }
            .dragConfiguration(DragConfiguration(allowMove: true))

            VStack(alignment: .leading, spacing: 4) {
                Text("Log (\(model.log.count) events)")
                    .font(.headline)
                if model.log.isEmpty {
                    Text("No drops delivered yet — expected on iOS 27.0 while dropConfiguration is attached.")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(model.log.suffix(8).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption.monospaced())
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle(model.listName(listID))
    }
}

#Preview {
    IntendedDropConfigurationDemoView()
}
