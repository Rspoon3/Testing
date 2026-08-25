import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

/// Shared model between `DropDestinationReplicaView` (plain `.dropDestination`) and
/// `ListDropTargetReplicaView` (`.listDropTarget`, from `ListDropTarget.swift`) — same UI, same
/// payload types, only the drop-handling mechanism differs between the two tabs.
struct ReplicaWishlist: Identifiable, Hashable {
    let id: Int
    let name: String
}

/// Mirrors `WishlistItemDragPayload`: a custom, same-app `Transferable` payload with its own
/// exported UTI (declared in Info.plist) — deliberately not `.data`, so it can't spuriously
/// match an unrelated external drag.
struct ReplicaItemPayload: Codable, Hashable, Identifiable, Transferable {
    let itemID: Int
    var id: Int { itemID }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .replicaItemPayload)
    }
}

extension UTType {
    static var replicaItemPayload: UTType {
        UTType(exportedAs: "com.rspoon3.TestDrive.replica-item-payload")
    }
}

let replicaWishlists = (0..<3).map { ReplicaWishlist(id: $0, name: "Wishlist \($0 + 1)") }
let replicaItemIDs = Array(0..<4)
