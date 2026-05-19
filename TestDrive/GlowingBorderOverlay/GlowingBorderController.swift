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

    /// Reveals the glow on every connected display using the supplied color.
    /// - Parameter color: The glow color.
    func show(color: Color) {
        currentColor = color
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
            let host = NSHostingView(rootView: GlowingBorderView(color: currentColor))
            host.frame = window.contentView?.bounds ?? screen.frame
            host.autoresizingMask = [.width, .height]
            window.contentView = host
            return window
        }
    }

    private func refreshWindowsIfVisible() {
        guard !windows.isEmpty else { return }
        show(color: currentColor)
    }
}
