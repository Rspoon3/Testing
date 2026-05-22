//
//  GlowingBorderController.swift
//  TestDrive
//

import AppKit
import SwiftUI

/// Manages one click-through panel per connected display, showing or hiding the glow border.
@MainActor
final class GlowingBorderController {
    private var windows: [GlowingBorderWindow] = []
    private var currentColor: Color = .red
    private var currentStyle: BorderStyle = .colored
    private var currentFireworksColorMode: FireworksColorMode = .fixed
    private var screenChangeObserver: (any NSObjectProtocol)?

    // MARK: - Initializer

    init() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refreshWindowsIfVisible() }
        }
    }

    nonisolated deinit {
        if let screenChangeObserver {
            NotificationCenter.default.removeObserver(screenChangeObserver)
        }
    }

    // MARK: - Public Helpers

    /// Reveals the glow on every connected display using the supplied color and style.
    /// - Parameters:
    ///   - color: The glow color. Ignored by styles whose `usesGlowColor` is false.
    ///   - style: The visual treatment to use.
    ///   - fireworksColorMode: When `style` resolves to `.fireworks`, controls
    ///     whether explosions use the chosen color, a varied palette, or a new
    ///     random color per launch.
    func show(color: Color, style: BorderStyle, fireworksColorMode: FireworksColorMode) {
        currentColor = color
        // Resolve meta-cases (e.g. `.random`) once per show so every screen renders
        // the same concrete effect and screen-change refreshes don't re-roll.
        currentStyle = style.resolved()
        currentFireworksColorMode = fireworksColorMode
        rebuildWindows()
        for window in windows {
            window.orderFrontRegardless()
        }
    }

    /// Removes the glow from every display.
    func hide() {
        for window in windows {
            window.orderOut(nil)
        }
        windows.removeAll()
    }

    // MARK: - Private Helpers

    private func rebuildWindows() {
        for window in windows {
            window.orderOut(nil)
        }
        windows = NSScreen.screens.map { screen in
            let window = GlowingBorderWindow(screen: screen)
            let host = NSHostingView(rootView: BorderOverlay(
                style: currentStyle,
                color: currentColor,
                screen: screen,
                fireworksColorMode: currentFireworksColorMode
            ))
            host.frame = window.contentView?.bounds ?? screen.frame
            host.autoresizingMask = [.width, .height]
            window.contentView = host
            return window
        }
    }

    private func refreshWindowsIfVisible() {
        guard !windows.isEmpty else { return }
        show(color: currentColor, style: currentStyle, fireworksColorMode: currentFireworksColorMode)
    }
}
