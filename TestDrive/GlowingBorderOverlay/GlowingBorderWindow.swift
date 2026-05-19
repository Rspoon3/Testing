//
//  GlowingBorderWindow.swift
//  TestDrive
//

import AppKit

/// A borderless, transparent, click-through panel that sits above every other window
/// and floats across all spaces so the glow is visible regardless of what the user is doing.
final class GlowingBorderWindow: NSPanel {

    // MARK: - Initializer

    /// Creates a panel sized to fully cover the supplied screen.
    /// - Parameter screen: The screen to overlay.
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        isMovableByWindowBackground = false
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        hidesOnDeactivate = false
        animationBehavior = .none
        setFrame(screen.frame, display: false)
    }

    // MARK: - Public Helpers

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
