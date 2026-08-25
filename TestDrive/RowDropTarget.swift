import SwiftUI
import UIKit
import UniformTypeIdentifiers

extension View {
    /// Like `listDropTarget` (`ListDropTarget.swift`), but installs its own `UIDropInteraction`
    /// directly on *this row's own view* instead of searching upward for the List's shared
    /// `UICollectionView` — so the row's own closures already know which row they belong to,
    /// with no `IndexPath` bookkeeping needed the way `listDropTarget` requires.
    ///
    /// Two things this needed, confirmed empirically rather than assumed:
    ///
    /// 1. **`.overlay`, not `.background`.** As a background, this view sits behind the row's
    ///    real content in z-order, so hit-testing for an incoming drag session resolves to the
    ///    foreground content instead and never reaches this view's own interaction at all —
    ///    `canHandle`/`sessionDidUpdate`/`performDrop` simply never fired. As the front-most
    ///    view at that point, it's the one hit-testing actually resolves to.
    /// 2. **No automatic hover highlight, even though the built-in
    ///    `_UICollectionViewDragDestinationController` doesn't need to be evicted here** (unlike
    ///    `listDropTarget`, this row-scoped interaction wins the session on its own, since it's
    ///    the closer/hit-tested view — tested leaving the built-in interaction in place, and
    ///    delivery still worked). The automatic per-row highlight turned out to never have been
    ///    a generic `UIDropInteraction` feature at all — it's bespoke rendering that only runs
    ///    inside the built-in controller's own `sessionDidUpdate`, which never gets called once
    ///    a closer interaction (ours) already claims the session. Hence `isTargeted` below:
    ///    there's no way to get that highlight for free, so this draws its own.
    ///
    /// - Parameters:
    ///   - isEnabled: When `false`, drags show no hover affordance and drops are refused.
    ///   - isTargeted: Set to `true` while a compatible drag hovers over this row, `false`
    ///     otherwise — drive a highlight from it (e.g. via `.listRowBackground`).
    ///   - handlers: One ``DropPayloadHandler`` per accepted payload type.
    func rowDropTarget(
        isEnabled: Bool = true,
        isTargeted: Binding<Bool>? = nil,
        accepting handlers: DropPayloadHandler...
    ) -> some View {
        modifier(RowDropTargetModifier(isEnabled: isEnabled, isTargeted: isTargeted, handlers: handlers))
    }
}

private struct RowDropTargetModifier: ViewModifier {
    let isEnabled: Bool
    let isTargeted: Binding<Bool>?
    let handlers: [DropPayloadHandler]

    func body(content: Content) -> some View {
        content.overlay(RowDropInstaller(isEnabled: isEnabled, isTargeted: isTargeted, handlers: handlers))
    }
}

private struct RowDropInstaller: UIViewRepresentable {
    let isEnabled: Bool
    let isTargeted: Binding<Bool>?
    let handlers: [DropPayloadHandler]

    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.backgroundColor = .clear
        view.isEnabled = isEnabled
        view.isTargeted = isTargeted
        view.handlers = handlers
        view.install()
        return view
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {
        uiView.isEnabled = isEnabled
        uiView.isTargeted = isTargeted
        uiView.handlers = handlers
        uiView.pushStateToDelegate()
    }

    final class InstallerView: UIView {
        var isEnabled = true
        var isTargeted: Binding<Bool>?
        var handlers: [DropPayloadHandler] = []
        private var dropDelegate: DropDelegate?

        /// This view itself is the drop target, so the interaction goes on immediately — no
        /// need to wait for the view hierarchy, and no ancestor collection view to find.
        func install() {
            guard dropDelegate == nil else { return }
            isUserInteractionEnabled = true
            let delegate = DropDelegate()
            dropDelegate = delegate
            addInteraction(UIDropInteraction(delegate: delegate))
            pushStateToDelegate()
        }

        func pushStateToDelegate() {
            dropDelegate?.isEnabled = isEnabled
            dropDelegate?.isTargeted = isTargeted
            dropDelegate?.handlers = handlers
        }
    }

    final class DropDelegate: NSObject, UIDropInteractionDelegate {
        var isEnabled = true
        var isTargeted: Binding<Bool>?
        var handlers: [DropPayloadHandler] = []

        func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
            isEnabled && session.items.contains { item in
                handlers.contains { $0.matches(item.itemProvider) }
            }
        }

        func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
            isTargeted?.wrappedValue = isEnabled
            return UIDropProposal(operation: isEnabled ? .copy : .cancel)
        }

        func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
            isTargeted?.wrappedValue = false
        }

        func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
            isTargeted?.wrappedValue = false
        }

        func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
            isTargeted?.wrappedValue = false
            for item in session.items {
                handlers.first { $0.matches(item.itemProvider) }?.load(item.itemProvider)
            }
        }
    }
}
