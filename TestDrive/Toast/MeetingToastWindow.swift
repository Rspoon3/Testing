//
//  MeetingToastWindow.swift
//  TestDrive
//

import AppKit

/// Borderless transparent panel that hosts the meeting toast at the top of a screen.
///
/// The panel does *not* ignore mouse events — users need to click Join/Dismiss — but it
/// stays above other windows and joins all spaces so it appears regardless of focus.
final class MeetingToastWindow: NSPanel {

    // MARK: - Initializer

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        ignoresMouseEvents = false
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        hidesOnDeactivate = false
        animationBehavior = .none
    }

    // MARK: - Public Helpers

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
