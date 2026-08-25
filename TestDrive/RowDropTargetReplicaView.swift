import SwiftUI

/// The same UI as ``DropDestinationReplicaView`` and ``ListDropTargetReplicaView``, but using
/// `.rowDropTarget` (`RowDropTarget.swift`) — an independent `UIDropInteraction` installed per
/// row instead of one shared across the whole list. This gets per-row attribution for free
/// (each row's own closure already knows which wishlist it is — no `IndexPath` bookkeeping),
/// but NOT a free hover highlight — turned out there's no such thing as one for a bypassed
/// interaction, so `isTargeted` drives one manually here instead.
struct RowDropTargetReplicaView: View {
    @State private var selectedWishlistID: Int?
    @State private var selectedItemID: Int?
    @State private var droppedOnSidebar: [(wishlistID: Int, itemID: Int)] = []
    @State private var sidebarDroppedURLs: [(wishlistID: Int, url: URL)] = []
    @State private var droppedItemPayloads: [Int] = []
    @State private var droppedURLs: [URL] = []
    @State private var hoveredWishlistID: Int?
    @State private var hoveredItemRowID: Int?

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
                wishlistRow(wishlist)
                    .tag(wishlist.id)
            }
            Section("Cross-column drops") {
                ForEach(droppedOnSidebar.indices, id: \.self) { index in
                    let drop = droppedOnSidebar[index]
                    Text("Item \(drop.itemID) → Wishlist \(drop.wishlistID)")
                }
                ForEach(sidebarDroppedURLs.indices, id: \.self) { index in
                    let drop = sidebarDroppedURLs[index]
                    Text("\(drop.url.absoluteString) → Wishlist \(drop.wishlistID)")
                }
            }
        }
        .navigationTitle("Wishlists")
    }

    private func wishlistRow(_ wishlist: ReplicaWishlist) -> some View {
        Label(wishlist.name, systemImage: "gift")
            // A bare `Label` only sizes to its own glyph+text — the drop target needs the full
            // row width/height so a drop lands wherever on the row, not just over the label.
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .background {
                if hoveredWishlistID == wishlist.id {
                    Capsule()
                        .fill(Color.gray.opacity(0.35))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                }
            }
            .rowDropTarget(
                isTargeted: Binding(
                    get: { hoveredWishlistID == wishlist.id },
                    set: { hoveredWishlistID = $0 ? wishlist.id : nil }
                ),
                accepting:
                    .payload(URL.self) { url in sidebarDroppedURLs.append((wishlist.id, url)) },
                    .payload(ReplicaItemPayload.self) { payload in
                        droppedOnSidebar.append((wishlist.id, payload.itemID))
                    }
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
                    itemRow(itemID)
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
    }

    private func itemRow(_ itemID: Int) -> some View {
        Text("Item \(itemID)")
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .contentShape(Rectangle())
            .background {
                if hoveredItemRowID == itemID {
                    Capsule()
                        .fill(Color.gray.opacity(0.45))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.red.opacity(0.2))
            .draggable(ReplicaItemPayload(itemID: itemID))
            .rowDropTarget(
                isTargeted: Binding(
                    get: { hoveredItemRowID == itemID },
                    set: { hoveredItemRowID = $0 ? itemID : nil }
                ),
                accepting:
                    .payload(ReplicaItemPayload.self) { payload in droppedItemPayloads.append(payload.itemID) },
                    .payload(URL.self) { url in droppedURLs.append(url) }
            )
    }
}

#Preview {
    RowDropTargetReplicaView()
}
