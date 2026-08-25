import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

/// A minimal, full-fidelity replica of `WishlistsView`'s two-column shape, testing TWO distinct
/// drag shapes side by side:
///
/// 1. **Same-list self-drag** (bottom section of the item list): drag an item row onto a
///    sibling item row, within the very same `List`/`UICollectionView`. This is what earlier
///    TestDrive experiments in this repo were exclusively testing.
/// 2. **Cross-column drag** (drag an item row over into the sidebar): this is what the real app
///    actually does — see `ItemDragSession`'s own doc comment: it "bridg[es] the drag side (the
///    item grid/list) to the drop side (the sidebar's wishlist rows), which live in **separate
///    split-view columns**." A same-`UICollectionView` self-drag is a fundamentally different
///    UIKit code path (the built-in drag-destination controller treats it as a potential
///    reorder) than a drag arriving from a different collection view entirely.
///
/// Run this on an iPad-class simulator/device (regular width) so both columns are visible at
/// once — the cross-column drag can't be performed at all if the split view is collapsed to a
/// single-column stack.
struct ContentView: View {
    private struct FakeWishlist: Identifiable, Hashable {
        let id: Int
        let name: String
    }

    /// Mirrors `WishlistItemDragPayload`: a custom, same-app `Transferable` payload with its
    /// own exported UTI (declared in Info.plist) — deliberately not `.data`, so it can't
    /// spuriously match an unrelated external drag.
    private struct ItemPayload: Codable, Hashable, Identifiable, Transferable {
        let itemID: Int
        var id: Int { itemID }

        static var transferRepresentation: some TransferRepresentation {
            CodableRepresentation(contentType: .replicaItemPayload)
        }
    }

    private let wishlists = (0..<3).map { FakeWishlist(id: $0, name: "Wishlist \($0 + 1)") }
    private let itemIDs = Array(0..<4)

    @State private var selectedWishlistID: Int?
    @State private var selectedItemID: Int?
    @State private var droppedOnSidebar: [(wishlistID: Int, itemID: Int)] = []
    @State private var sidebarDroppedURLs: [(wishlistID: Int, url: URL)] = []
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

    // MARK: - Sidebar (drop-only — mirrors WishlistsView's sidebar rows)

    private var sidebar: some View {
        List(selection: $selectedWishlistID) {
            ForEach(wishlists) { wishlist in
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

    private func wishlistRow(_ wishlist: FakeWishlist) -> some View {
        let decoratedRow = Label(wishlist.name, systemImage: "gift")

        return wishlistRowDropDestinations(decoratedRow, wishlistID: wishlist.id)
    }

    /// Same wrapper-function shape as `WishlistsView.rowDropDestinations(_:row:)`.
    @ViewBuilder
    private func wishlistRowDropDestinations(_ view: some View, wishlistID: Int) -> some View {
        if #available(iOS 27, *) {
            view
                .dropDestination(for: URL.self) { urls, _ in
                    guard let url = urls.first else { return }
                    sidebarDroppedURLs.append((wishlistID, url))
                }
                .dropDestination(for: ItemPayload.self) { payloads, _ in
                    guard let payload = payloads.first else { return }
                    droppedOnSidebar.append((wishlistID, payload.itemID))
                }
        } else {
            view
                .dropDestination(for: URL.self) { urls, _ in
                    guard let url = urls.first else { return false }
                    sidebarDroppedURLs.append((wishlistID, url))
                    return true
                }
                .dropDestination(for: ItemPayload.self) { payloads, _ in
                    guard let payload = payloads.first else { return false }
                    droppedOnSidebar.append((wishlistID, payload.itemID))
                    return true
                }
        }
    }

    // MARK: - Detail (draggable items — mirrors ItemListLayout rows)

    private var detailList: some View {
        List(selection: $selectedItemID) {
            Section("Drag this URL over into the SIDEBAR") {
                Text("https://apple.com")
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .listRowBackground(Color.green.opacity(0.15))
                    .draggable(URL(string: "https://apple.com")!)
            }
            Section("Drag an item row over into the SIDEBAR (cross-column — the real app's shape)") {
                ForEach(itemIDs, id: \.self) { itemID in
                    Text("Item \(itemID)")
                        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                        .listRowBackground(Color.blue.opacity(0.15))
                        .draggable(ItemPayload(itemID: itemID))
                        .tag(itemID)
                }
            }
            Section("Same-list self-drag (drag onto a sibling row below — what earlier tests used)") {
                ForEach(itemIDs, id: \.self) { itemID in
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
        let decoratedRow = Text("Item \(itemID)")
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .listRowBackground(Color.red.opacity(0.2))
            .draggable(ItemPayload(itemID: itemID))

        return itemRowDropDestinations(decoratedRow, itemID: itemID)
    }

    /// Same wrapper-function shape as `WishlistsView.rowDropDestinations(_:row:)` — the row's
    /// base content is built once, then handed to this separate function which appends the
    /// `.dropDestination` calls, rather than chaining them inline where the row is built.
    @ViewBuilder
    private func itemRowDropDestinations(_ view: some View, itemID: Int) -> some View {
        if #available(iOS 27, *) {
            view
                .dropDestination(for: ItemPayload.self) { payloads, _ in
                    guard let payload = payloads.first else { return }
                    droppedItemPayloads.append(payload.itemID)
                }
                .dropDestination(for: URL.self) { urls, _ in
                    guard let url = urls.first else { return }
                    droppedURLs.append(url)
                }
        } else {
            view
                .dropDestination(for: ItemPayload.self) { payloads, _ in
                    guard let payload = payloads.first else { return false }
                    droppedItemPayloads.append(payload.itemID)
                    return true
                }
                .dropDestination(for: URL.self) { urls, _ in
                    guard let url = urls.first else { return false }
                    droppedURLs.append(url)
                    return true
                }
        }
    }
}

extension UTType {
    fileprivate static var replicaItemPayload: UTType {
        UTType(exportedAs: "com.rspoon3.TestDrive.replica-item-payload")
    }
}

#Preview {
    ContentView()
}
