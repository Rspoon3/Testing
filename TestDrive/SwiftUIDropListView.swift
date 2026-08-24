import SwiftUI

/// SwiftUI-only counterpart to ``DropCollectionView`` — a plain `List` of dropped URLs with
/// `.dropDestination(for: URL.self)` attached directly to the `List`. This is the broken half of
/// the comparison: unlike ``DropCollectionView``'s UIKit `UICollectionViewDropDelegate`, this
/// never registers an external (cross-app) drop at all — no hover highlight, no delivery, the
/// dragged URL just snaps back. See FB24490454.
struct SwiftUIDropListView: View {
    @State private var droppedURLs: [URL] = []

    var body: some View {
        List {
            if droppedURLs.isEmpty {
                Text("SWIFTUI DROP TARGET (drop a URL anywhere here)")
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .multilineTextAlignment(.center)
                    .listRowBackground(Color.red.opacity(0.3))
            } else {
                ForEach(droppedURLs, id: \.self) { url in
                    Text(url.absoluteString)
                }
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            print("SwiftUI DROPPED: \(urls)")
            droppedURLs.append(contentsOf: urls)
            return true
        }
    }
}

#Preview {
    SwiftUIDropListView()
}
