import SwiftUI
import UIKit
import UniformTypeIdentifiers

extension View {
    /// Makes this `List`/`Form` accept drops of the given payload types, working around
    /// FB24490454 (SwiftUI `dropDestination` never receives external, cross-app drops anywhere
    /// over a list): installs our own `UIDropInteraction` on the list's backing
    /// `UICollectionView`, replacing the built-in `_UICollectionViewDragDestinationController`
    /// interaction — which otherwise claims every drop session away from SwiftUI's root
    /// `DragAndDropBridge` (where all `dropDestination` regions live) and then refuses to
    /// service external drops. No SwiftUI-level placement (row modifier, near-invisible overlay,
    /// `ZStack` on top) can win the session back.
    ///
    /// One interaction serves every handler: each dropped item is routed to the first handler
    /// whose imported content types match it, so a mixed session (a URL and an image together)
    /// delivers to both handlers — unlike stacking one modifier per type, where each application
    /// would install a competing interaction and UIKit would hand the whole session to only one.
    ///
    /// Removing the built-in interaction also disables SwiftUI's own list drop handling on this
    /// list (`onMove` reorder, `onInsert`, in-app drops onto rows) — only adopt on screens that
    /// use none of those.
    ///
    /// ```swift
    /// struct InboxView: View {
    ///     @State private var links: [URL] = []
    ///
    ///     var body: some View {
    ///         List(links, id: \.self) { link in
    ///             Text(link.absoluteString)
    ///         }
    ///         .listDropTarget(accepting: .payload(URL.self, into: $links))
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isEnabled: When `false`, drags show no hover affordance and drops are refused —
    ///     e.g. for read-only viewers.
    ///   - handlers: One ``DropPayloadHandler`` per accepted payload type, built with
    ///     ``DropPayloadHandler/payload(_:action:)`` or ``DropPayloadHandler/payload(_:into:)``.
    func listDropTarget(isEnabled: Bool = true, accepting handlers: DropPayloadHandler...) -> some View {
        modifier(ListDropTargetModifier(isEnabled: isEnabled, handlers: handlers))
    }
}

/// One accepted payload type: which UTTypes it matches (derived from `Transferable`) and how to
/// load-and-deliver an item of it. Type-erased so any mix of payload types shares one interaction.
struct DropPayloadHandler {
    let typeIdentifiers: [String]
    let load: @MainActor (NSItemProvider) -> Void

    /// Accepts `type`, delivering each dropped payload to `action` on the main actor. Matching
    /// UTTypes come from `Transferable.importedContentTypes()` — the types the payload can be
    /// created *from*, which is what receiving a drop means.
    static func payload<Payload: Transferable & Sendable>(
        _ type: Payload.Type,
        action: @MainActor @escaping (Payload) -> Void
    ) -> DropPayloadHandler {
        DropPayloadHandler(
            typeIdentifiers: Payload.importedContentTypes().map(\.identifier)
        ) { provider in
            _ = provider.loadTransferable(type: Payload.self) { result in
                guard case .success(let payload) = result else { return }
                Task { @MainActor in
                    action(payload)
                }
            }
        }
    }

    /// Accepts `type`, appending each dropped payload to `binding`.
    static func payload<Payload: Transferable & Sendable>(
        _ type: Payload.Type,
        into binding: Binding<[Payload]>
    ) -> DropPayloadHandler {
        payload(type) { binding.wrappedValue.append($0) }
    }

    func matches(_ provider: NSItemProvider) -> Bool {
        typeIdentifiers.contains(where: provider.hasItemConformingToTypeIdentifier)
    }
}

private struct ListDropTargetModifier: ViewModifier {
    let isEnabled: Bool
    let handlers: [DropPayloadHandler]

    func body(content: Content) -> some View {
        content.background(CollectionViewDropInstaller(isEnabled: isEnabled, handlers: handlers))
    }
}

// MARK: - Installation

/// Invisible view that locates the target `UICollectionView` and installs the drop interaction
/// on it (once). Attached to a row, the collection view is an ancestor; attached to the `List`
/// itself, this background is a *sibling* of the list's host view — so the search walks up the
/// superview chain first, then from each ancestor searches descendants for a collection view
/// overlapping this view's frame. Lists can materialize a beat after the background, so the
/// search retries briefly before giving up.
private struct CollectionViewDropInstaller: UIViewRepresentable {
    let isEnabled: Bool
    let handlers: [DropPayloadHandler]

    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.isEnabled = isEnabled
        view.handlers = handlers
        return view
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {
        uiView.isEnabled = isEnabled
        uiView.handlers = handlers
        uiView.pushStateToDelegate()
    }

    final class InstallerView: UIView {
        var isEnabled = true
        var handlers: [DropPayloadHandler] = []
        private var dropDelegate: DropDelegate?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil, dropDelegate == nil else { return }
            attemptInstall(retriesLeft: 5)
        }

        private func attemptInstall(retriesLeft: Int) {
            guard window != nil, dropDelegate == nil else { return }
            guard let collectionView = findCollectionView() else {
                if retriesLeft > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        self?.attemptInstall(retriesLeft: retriesLeft - 1)
                    }
                }
                return
            }

            // A recycled cell can destroy and recreate this installer (row placement). Adopt a
            // live delegate a previous incarnation already installed, and sweep one whose owner
            // died — its weakly-held delegate is nil, which would otherwise leave a zombie
            // interaction claiming sessions with default answers.
            //
            // Also REMOVE the collection view's built-in drop interaction
            // (`_UICollectionViewDragDestinationController`): with both present, it still wins
            // the session while hovering over existing cells (only empty list space fell to
            // ours) and refuses external drops there.
            for interaction in collectionView.interactions {
                guard let drop = interaction as? UIDropInteraction else { continue }
                if let existing = drop.delegate as? DropDelegate {
                    dropDelegate = existing
                    pushStateToDelegate()
                    return
                }
                collectionView.removeInteraction(drop)
            }

            let delegate = DropDelegate()
            dropDelegate = delegate
            collectionView.addInteraction(UIDropInteraction(delegate: delegate))
            pushStateToDelegate()
        }

        func pushStateToDelegate() {
            dropDelegate?.isEnabled = isEnabled
            dropDelegate?.handlers = handlers
        }

        private func findCollectionView() -> UICollectionView? {
            // Row placement: the collection view is a direct ancestor.
            var ancestor = superview
            while let view = ancestor {
                if let collectionView = view as? UICollectionView { return collectionView }
                ancestor = view.superview
            }

            // List placement: this background is a sibling of the list's host — search each
            // ancestor's subtree for a collection view overlapping our own frame, nearest
            // ancestor first so an unrelated list elsewhere on screen can't win.
            ancestor = superview
            while let view = ancestor {
                if let collectionView = firstDescendantCollectionView(of: view) {
                    return collectionView
                }
                ancestor = view.superview
            }
            return nil
        }

        private func firstDescendantCollectionView(of root: UIView) -> UICollectionView? {
            var queue = root.subviews
            while !queue.isEmpty {
                let view = queue.removeFirst()
                if let collectionView = view as? UICollectionView {
                    let frameHere = collectionView.convert(collectionView.bounds, to: self)
                    if frameHere.intersects(bounds) {
                        return collectionView
                    }
                }
                queue.append(contentsOf: view.subviews)
            }
            return nil
        }
    }

    final class DropDelegate: NSObject, UIDropInteractionDelegate {
        var isEnabled = true
        var handlers: [DropPayloadHandler] = []

        func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
            isEnabled && session.items.contains { item in
                handlers.contains { $0.matches(item.itemProvider) }
            }
        }

        func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
            UIDropProposal(operation: isEnabled ? .copy : .cancel)
        }

        func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
            for item in session.items {
                handlers.first { $0.matches(item.itemProvider) }?.load(item.itemProvider)
            }
        }
    }
}
