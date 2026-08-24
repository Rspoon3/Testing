import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

// A minimal reproduction lab for the iOS 27 drag-and-drop APIs, round 3.
//
// Rounds 1-2 established:
//   - The new drag side (`.draggable(containerItemID:)` + `.dragContainer` +
//     `.dragConfiguration(allowMove:)`) works.
//   - Both `dropDestination` overloads work BARE, but attaching `.dropConfiguration` kills drop
//     delivery entirely on iOS 27.0 — even when its closure runs and returns `.move`.
//
// Round 3 verifies the production candidate that needs no `.dropConfiguration`:
//   - `onDragSessionUpdated` on the drag container records the in-flight drag's source list
//     the moment the session starts (via `draggedItemIDs`), and clears it when it ends.
//   - Each row's `dropDestination(for:isEnabled:action:)` disables itself while the active
//     drag originates from its own list — a disabled destination shows no highlight and no
//     accept badge, giving hover-time same-list suppression without `.dropConfiguration`.
//
// State transitions are appended to the on-screen log so they're machine-readable from the
// accessibility hierarchy.

// MARK: - Model

struct LabItem: Codable, Hashable, Identifiable, Transferable {
    struct ID: Codable, Hashable, Sendable {
        let itemID: UUID
        let sourceListID: UUID
    }

    let itemID: UUID
    let sourceListID: UUID
    let name: String

    var id: ID { ID(itemID: itemID, sourceListID: sourceListID) }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

struct LabList: Identifiable, Hashable {
    let id: UUID
    let name: String
}

@MainActor
@Observable
final class LabModel {
    let lists: [LabList]
    var items: [LabItem]
    var log: [String] = []

    /// The source list of the in-flight item drag, if any — set from `onDragSessionUpdated`.
    /// Rows disable their item drop destination while this matches their own list.
    var activeDragSourceListID: UUID?

    init() {
        let listA = LabList(id: UUID(), name: "List A")
        let listB = LabList(id: UUID(), name: "List B")
        lists = [listA, listB]
        items = ["Apple", "Banana", "Cherry", "Date"].map {
            LabItem(itemID: UUID(), sourceListID: listA.id, name: $0)
        }
    }

    func listName(_ id: UUID) -> String {
        lists.first(where: { $0.id == id })?.name ?? "?"
    }

    func count(in listID: UUID) -> Int {
        items.count(where: { $0.sourceListID == listID })
    }

    func items(withIDs ids: [LabItem.ID]) -> [LabItem] {
        ids.compactMap { id in items.first { $0.itemID == id.itemID } }
    }

    func receive(_ dropped: [LabItem], into listID: UUID, via api: String) {
        note("\(api): \(dropped.map(\.name).joined(separator: "+")) -> \(listName(listID))")
        for item in dropped {
            guard let index = items.firstIndex(where: { $0.itemID == item.itemID }) else { continue }
            items[index] = LabItem(itemID: item.itemID, sourceListID: listID, name: item.name)
        }
    }

    func setActiveDragSource(_ listID: UUID?) {
        guard activeDragSourceListID != listID else { return }
        activeDragSourceListID = listID
        if let listID {
            note("dragSession: source = \(listName(listID))")
        } else {
            note("dragSession: cleared")
        }
    }

    func note(_ message: String) {
        log.append(message)
    }
}

// MARK: - View

struct DragDropLabView: View {
    @State private var model = LabModel()

    var body: some View {
        HStack(spacing: 0) {
            targetsColumn
                .frame(width: 340)
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                Text("isEnabled-driven same-list suppression (no dropConfiguration)")
                    .font(.headline)

                itemsArea

                logArea

                Spacer(minLength: 0)
            }
            .padding()
        }
    }

    // MARK: Drop side

    private var targetsColumn: some View {
        List(model.lists) { list in
            row(for: list)
        }
    }

    private func row(for list: LabList) -> some View {
        HStack {
            Text(list.name)
                .font(.headline)
            Spacer()
            Text("\(model.count(in: list.id)) items")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .accessibilityIdentifier("drop-\(list.name)")
        .dropDestination(for: URL.self) { urls, _ in
            model.note("urlDrop: \(urls.count) url(s) -> \(model.listName(list.id))")
        }
        // Disabled while the in-flight drag started in this very list: a disabled destination
        // shows no highlight/accept badge during hover and rejects the drop outright.
        .dropDestination(
            for: LabItem.self,
            isEnabled: model.activeDragSourceListID != list.id
        ) { items, _ in
            model.receive(items, into: list.id, via: "newDrop")
        }
    }

    // MARK: Drag side

    private var itemsArea: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(model.items, id: \.itemID) { item in
                    card(for: item)
                }
            }
        }
        .frame(maxHeight: 280)
        .dragContainer(for: LabItem.self) { ids in
            model.items(withIDs: ids)
        }
        .dragConfiguration(DragConfiguration(allowMove: true))
        .onDragSessionUpdated { session in
            switch session.phase {
            case .initial, .active:
                if let first = session.draggedItemIDs(for: LabItem.ID.self).first {
                    model.setActiveDragSource(first.sourceListID)
                }
            case .ended, .dataTransferCompleted:
                model.setActiveDragSource(nil)
            case .ending:
                // Don't clear yet: the drop hasn't been delivered, and flipping `isEnabled`
                // out from under an in-delivery drop could cancel it.
                break
            @unknown default:
                model.setActiveDragSource(nil)
            }
        }
    }

    private func card(for item: LabItem) -> some View {
        VStack(spacing: 4) {
            Text(item.name)
                .font(.headline)
            Text(model.listName(item.sourceListID))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 150, height: 90)
        .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier("card-\(item.name)")
        .draggable(containerItemID: item.id)
    }

    // MARK: Log

    private var logArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Log (\(model.log.count) events)")
                .font(.headline)
            ForEach(Array(model.log.suffix(12).enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.caption.monospaced())
            }
        }
        .accessibilityIdentifier("event-log")
    }
}

#Preview {
    DragDropLabView()
}
