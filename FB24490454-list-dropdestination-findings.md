# `dropDestination(for:)` inside a `List` silently fails for system UTIs, but works fine for a custom app-private `Transferable`

**Filed as FB24490454.** This refines that report with a more precise root cause than "external
drops die in a `List`" — the actual trigger is the payload's *UTI*, not where the drag
originates from.

## Environment

- Xcode 26 beta / iOS 27.0 SDK, deployment target iOS 26.0
- Reproduced on both the iOS Simulator and a physical iPhone 15 Pro (iOS 26.6)

## Symptom

A row inside a `List` with two stacked `dropDestination` modifiers:

```swift
Text("Row")
    .draggable(SomePayload(...))
    .dropDestination(for: URL.self) { urls, _ in
        // never fires — dropping a URL (from Safari, Notes, or a same-app
        // `.draggable(URL(...))` row) onto this row does nothing at all: no hover
        // highlight, no insertion indicator, no console output, nothing.
        return true
    }
    .dropDestination(for: SomePayload.self) { payloads, _ in
        // fires reliably, every time
        return true
    }
```

`SomePayload` is a small `Codable & Transferable` struct with its own **exported UTI** declared
in Info.plist (`UTExportedTypeDeclarations`), e.g. `CodableRepresentation(contentType:
.somePayloadUTI)`.

The `URL` destination never receives anything — not just from external apps, but from a
same-app `.draggable(URL(...))` row dragged onto this exact same list. The `SomePayload`
destination on the *same row* works every time.

## What we ruled out

We built a series of increasingly-faithful repro apps to isolate the variable. None of the
following turned out to matter:

- **List style** (`.insetGrouped`, `.sidebar`, `.plain`, default) — identical failure in all four.
- **Whether the `List` uses `List(selection:)` with tagged rows** vs. a plain `List` — no
  difference.
- **Whether the `List` is a genuine `NavigationSplitView` column** vs. a standalone `List` styled
  to look like one — no difference.
- **Same-list self-drag vs. cross-column drag** (dragging a row onto a sibling row in the *same*
  `List`, vs. dragging a row from one `List`/column into a *different* `List` in another
  `NavigationSplitView` column) — this looked promising for a while (same-list self-drag is a
  UIKit reorder-shaped gesture and could plausibly be swallowed differently), but the URL case
  fails identically either way once you actually test it.
- **Whether the modifiers are chained inline where the row is built**, vs. attached from a
  separate helper function that takes the pre-built row as a parameter and returns it further
  decorated (a common pattern for keeping row-building code organized) — no difference.
- **Wrapping the `URL` in a distinct Swift type via `ProxyRepresentation`:**

  ```swift
  struct ProxiedURLPayload: Transferable {
      let url: URL
      static var transferRepresentation: some TransferRepresentation {
          ProxyRepresentation(exporting: \.url)
      }
  }
  ```

  This is a different Swift type from `URL`, but `ProxyRepresentation(exporting:)` just forwards
  to the proxy value's own `Transferable` conformance — so on the wire it still advertises
  `URL`'s own registered UTI (`public.url`), not a new one. It fails identically to a plain
  `URL` drop. **This is the key result: it's the actual UTI advertised in the drag session that
  determines success or failure, not the Swift type wrapping it, not the drag's origin, and not
  any list structural property.**

Every payload using a *system-recognized* UTI (`public.url` confirmed; almost certainly
`public.image`, `public.plain-text`, `public.file-url`, etc. by the same mechanism) fails. Every
payload using an app-private *exported* UTI succeeds, unconditionally, in every structural variant
we tried.

## Why: it's not an interceptor, it's the delivery mechanism itself

A `List`'s backing `UICollectionView` has exactly one `UIDropInteraction` installed on it by
default, whose delegate is the private class `_UICollectionViewDragDestinationController`. The
natural assumption is that this controller sits in front of SwiftUI's `dropDestination` and
steals sessions from it for recognized types, refusing to hand them off.

We tested that assumption directly: using the Objective-C runtime, we patched
`_UICollectionViewDragDestinationController`'s `-dropInteraction:canHandle:` to
unconditionally return `false`, process-wide.

```swift
let cls = NSClassFromString("_UICollectionViewDragDestinationController")!
let selector = #selector(UIDropInteractionDelegate.dropInteraction(_:canHandle:))
let method = class_getInstanceMethod(cls, selector)!
typealias CanHandleBlock = @convention(block) (AnyObject, UIDropInteraction, UIDropSession) -> Bool
let replacement: CanHandleBlock = { _, _, _ in false }
method_setImplementation(method, imp_implementationWithBlock(replacement))
```

Result: **every drop stopped working**, including the custom-payload case that had worked
reliably in every prior test. That rules out the "hostile interceptor" model entirely. If it
were just stealing sessions from an independent SwiftUI-native drop path, declining should have
let that other path take over — instead, declining killed delivery for everyone.

The conclusion: `_UICollectionViewDragDestinationController` **is** the mechanism SwiftUI's
`List` uses to relay an *accepted* drop session to whichever `dropDestination` region matches it.
There's no separate underlying path. The actual defect is inside this controller's own
accepted-session → matching-`dropDestination`-region routing, and it appears to special-case (and
mis-route or drop) sessions carrying certain system UTIs, while correctly relaying app-private
ones. This can't be fixed by declining the session from outside — declining just removes the
only channel there is.

## Workaround

Since the defect is inside the built-in controller's routing and can't be selectively patched,
the only reliable fix we found is to **remove that interaction entirely** and install your own
`UIDropInteractionDelegate` on the collection view, handling `canHandle`/`performDrop` yourself
based on the item provider's registered type identifiers — bypassing the buggy relay completely
rather than trying to influence it.

```swift
// Simplified sketch — walk up from a view placed as a List's background/row content to find
// the backing UICollectionView, remove its existing UIDropInteraction, and install your own:
for interaction in collectionView.interactions {
    if let drop = interaction as? UIDropInteraction {
        collectionView.removeInteraction(drop)
    }
}
collectionView.addInteraction(UIDropInteraction(delegate: myOwnDelegate))
```

Once your own delegate is the only one installed, `canHandle`/`performDrop` fire correctly for
every UTI, system-recognized or not, because SwiftUI's own (defective, for this case)
`dropDestination` relay is no longer in the loop for that interaction at all.

## tl;dr

- `dropDestination(for:)` inside a `List` fails specifically for payloads carrying
  system-recognized UTIs (confirmed: `public.url`), regardless of Swift wrapper type, list
  style, selection state, split-view hosting, or same-list vs. cross-list drag.
- It is not an interceptor problem — the private `_UICollectionViewDragDestinationController`
  *is* SwiftUI's delivery mechanism for `List` drops, confirmed by fully disabling it and
  breaking every drop, not just the broken ones.
- The only working fix is removing that interaction and implementing `UIDropInteractionDelegate`
  yourself.
