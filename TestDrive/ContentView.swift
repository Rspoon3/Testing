import SwiftUI

/// Three tabs, same UI, three different drop mechanisms:
/// - ``DropDestinationReplicaView``: plain SwiftUI `.dropDestination`.
/// - ``ListDropTargetReplicaView``: the shipped FB24490454 workaround, `.listDropTarget`,
///   scoped to the whole list.
/// - ``RowDropTargetReplicaView``: same workaround, scoped per row instead — regains per-row
///   attribution and UIKit's automatic hover highlight without any manual bookkeeping.
struct ContentView: View {
    var body: some View {
        TabView {
            DropDestinationReplicaView()
                .tabItem { Label("dropDestination", systemImage: "arrow.down.doc") }
            ListDropTargetReplicaView()
                .tabItem { Label("listDropTarget", systemImage: "shippingbox") }
            RowDropTargetReplicaView()
                .tabItem { Label("rowDropTarget", systemImage: "square.stack") }
        }
    }
}

#Preview {
    ContentView()
}
