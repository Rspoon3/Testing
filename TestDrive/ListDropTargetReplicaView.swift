import SwiftUI

/// The same UI as ``DropDestinationReplicaView``, but every `.dropDestination` is replaced with
/// `.listDropTarget` (`ListDropTarget.swift`) — the shipped FB24490454 workaround that removes
/// the List's built-in `UIDropInteraction` and installs its own.
///
/// `.listDropTarget` is attached to the *List as a whole*, not per row (matching how it's
/// actually used in the real app, on `ItemsView`'s outer container) — its delegate has no
/// concept of index path, so it can't distinguish which row a drop landed on the way row-level
/// `.dropDestination` could. That's a real, known limitation, not an oversight: dropping onto
/// any row in the sidebar records the drop generically rather than against a specific wishlist.
/// See ``RowDropTargetReplicaView`` for a per-row variant that doesn't have this limitation.
struct ListDropTargetReplicaView: View {
    @State private var selectedWishlistID: Int?
    @State private var selectedItemID: Int?
    @State private var sidebarDroppedItemPayloads: [Int] = []
    @State private var sidebarDroppedURLs: [URL] = []
    @State private var droppedItemPayloads: [Int] = []
    @State private var droppedURLs: [URL] = []

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if selectedWishlistID != nil {
                detailList
            } else {
                ContentUnavailableView("No Wishlist Selected", systemImage: "sidebar.left")
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedWishlistID) {
            ForEach(replicaWishlists) { wishlist in
                Label(wishlist.name, systemImage: "gift")
                    .tag(wishlist.id)
            }
            Section("Cross-column drops (list-wide — no per-row attribution)") {
                ForEach(sidebarDroppedItemPayloads, id: \.self) { id in
                    Text("Item \(id)")
                }
                ForEach(sidebarDroppedURLs, id: \.self) { url in
                    Text(url.absoluteString)
                }
            }
        }
        .navigationTitle("Wishlists")
        .listDropTarget(
            accepting:
                .payload(URL.self) { url in sidebarDroppedURLs.append(url) },
                .payload(ReplicaItemPayload.self) { payload in sidebarDroppedItemPayloads.append(payload.itemID) }
        )
    }

    // MARK: - Detail

    private var detailList: some View {
        List(selection: $selectedItemID) {
            Section("Drag this URL over into the SIDEBAR") {
                Text("https://apple.com")
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .listRowBackground(Color.green.opacity(0.15))
                    .draggable(URL(string: "https://apple.com")!)
            }
            Section("Drag an item row over into the SIDEBAR (cross-column — the real app's shape)") {
                ForEach(replicaItemIDs, id: \.self) { itemID in
                    Text("Item \(itemID)")
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        .listRowBackground(Color.blue.opacity(0.15))
                        .draggable(ReplicaItemPayload(itemID: itemID))
                        .tag(itemID)
                }
            }
            Section("Same-list self-drag (drag onto a sibling row below)") {
                ForEach(replicaItemIDs, id: \.self) { itemID in
                    Text("Item \(itemID)")
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        .listRowBackground(Color.red.opacity(0.2))
                        .draggable(ReplicaItemPayload(itemID: itemID))
                        .tag(itemID + 1000)
                }
            }
            Section("Dropped local payloads (same-list): \(droppedItemPayloads.count)") {
                ForEach(droppedItemPayloads, id: \.self) { id in
                    Text("Item \(id)")
                }
            }
            Section("Dropped URLs (same-list): \(droppedURLs.count)") {
                ForEach(droppedURLs, id: \.self) { url in
                    Text(url.absoluteString)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Items")
        .listDropTarget(
            accepting:
                .payload(URL.self) { url in droppedURLs.append(url) },
                .payload(ReplicaItemPayload.self) { payload in droppedItemPayloads.append(payload.itemID) }
        )
    }
}

#Preview {
    ListDropTargetReplicaView()
}
