import ObjectiveC
import UIKit

/// Experiment (dead end — kept for documentation, not called; see `TestDriveApp.init()`):
/// instead of walking the view hierarchy to remove/replace the built-in `UIDropInteraction` per
/// screen (`ListDropTarget.swift`'s shipped workaround), patch
/// `_UICollectionViewDragDestinationController`'s own `-dropInteraction:canHandle:`
/// implementation at the Objective-C runtime level, once, for the whole process, forcing it to
/// always answer `false`.
///
/// Result: this broke ALL drops, including the `ItemPayload` case that worked fine without any
/// workaround. That means this controller isn't a hostile interceptor sitting in front of
/// SwiftUI's `dropDestination` and stealing sessions from it — it's the actual mechanism SwiftUI
/// itself uses to relay an *accepted* session to a matching `dropDestination` region inside a
/// `List`. There's no independent SwiftUI-native interaction underneath it to catch what it
/// declines; declining kills the session for everyone. The real bug must be in how this
/// controller's internal relay routes an accepted session to the right `dropDestination` handler
/// for certain UTIs (e.g. `public.url`) specifically — not whether it accepts the session at all.
/// That's why `ListDropTarget.swift` has to fully remove this interaction and become the sole
/// `UIDropInteractionDelegate` itself, bypassing the buggy relay entirely, rather than merely
/// nudging this controller out of the way.
///
/// Private API regardless — fine for this local investigation, but not something to ship: Apple
/// can rename or restructure this class at any time, and using an undocumented/private class
/// name would be a static-analysis/App-Review red flag in the real app.
enum DragDestinationControllerSwizzle {
    private static var didSwizzle = false
    private static var original: (@convention(c) (AnyObject, Selector, UIDropInteraction, UIDropSession) -> Bool)?

    static func install() {
        guard !didSwizzle else { return }
        didSwizzle = true

        guard let cls = NSClassFromString("_UICollectionViewDragDestinationController") else {
            print("🩹 swizzle FAILED — _UICollectionViewDragDestinationController not found (class renamed?)")
            return
        }

        let selector = #selector(UIDropInteractionDelegate.dropInteraction(_:canHandle:))
        guard let method = class_getInstanceMethod(cls, selector) else {
            print("🩹 swizzle FAILED — \(cls) doesn't implement dropInteraction:canHandle:")
            return
        }

        typealias CanHandleIMP = @convention(c) (AnyObject, Selector, UIDropInteraction, UIDropSession) -> Bool
        original = unsafeBitCast(method_getImplementation(method), to: CanHandleIMP.self)

        typealias CanHandleBlock = @convention(block) (AnyObject, UIDropInteraction, UIDropSession) -> Bool
        let replacement: CanHandleBlock = { _, interaction, session in
            let types = session.items.flatMap(\.itemProvider.registeredTypeIdentifiers)
            print("🩹 swizzled canHandle types=\(types) — forcing false (was going to claim this)")
            return false
        }
        method_setImplementation(method, imp_implementationWithBlock(replacement))
        print("🩹 swizzle installed on \(cls)")
    }

    /// Restores the original implementation, in case forcing `false` unconditionally turns out
    /// to break something else (e.g. genuine list reordering) and a more surgical replacement is
    /// needed next.
    static func uninstall() {
        guard didSwizzle, let original,
              let cls = NSClassFromString("_UICollectionViewDragDestinationController"),
              let method = class_getInstanceMethod(cls, #selector(UIDropInteractionDelegate.dropInteraction(_:canHandle:)))
        else { return }
        method_setImplementation(method, unsafeBitCast(original, to: IMP.self))
        didSwizzle = false
        print("🩹 swizzle removed from \(cls)")
    }
}
