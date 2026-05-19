//
//  MeetingToastController.swift
//  TestDrive
//

import AppKit
import SwiftUI

/// Manages the meeting toast window — placement near the top of the main screen,
/// slide-down animation, and click-through-free Join/Dismiss buttons.
@MainActor
final class MeetingToastController {
    private static let toastWidth: CGFloat = 460
    private static let toastHeight: CGFloat = 80
    private static let topInset: CGFloat = 18
    private static let slideDuration: TimeInterval = 0.32

    private var window: MeetingToastWindow?
    private var hostingView: NSHostingView<MeetingToastView>?
    private var onJoin: ((URL) -> Void)?
    private var onDismiss: (() -> Void)?

    /// Whether the toast is currently presented.
    var isVisible: Bool { window?.isVisible == true }

    // MARK: - Public Helpers

    /// Presents the toast with the supplied content. Replaces any existing toast.
    /// - Parameters:
    ///   - content: What to display.
    ///   - onJoin: Invoked when the user taps "Join".
    ///   - onDismiss: Invoked when the user taps the close button or the toast hides automatically.
    func show(
        _ content: MeetingToastContent,
        onJoin: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) },
        onDismiss: @escaping () -> Void = { }
    ) {
        self.onJoin = onJoin
        self.onDismiss = onDismiss

        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let target = onScreenFrame(in: screen)
        let start = offScreenFrame(in: screen)

        let view = MeetingToastView(
            content: content,
            onJoin: { [weak self] url in self?.handleJoin(url) },
            onDismiss: { [weak self] in self?.hide() }
        )

        if let hostingView {
            hostingView.rootView = view
        } else {
            let host = NSHostingView(rootView: view)
            host.autoresizingMask = [.width, .height]
            hostingView = host
        }

        let panel: MeetingToastWindow
        if let existing = window {
            panel = existing
        } else {
            panel = MeetingToastWindow(contentRect: start)
            panel.contentView = hostingView
            window = panel
        }

        panel.setFrame(start, display: false)
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = Self.slideDuration
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(target, display: true)
        }
    }

    /// Hides the toast with a slide-up animation, invoking the stored dismiss handler.
    func hide() {
        guard let panel = window else { return }
        guard let screen = panel.screen ?? NSScreen.main else {
            panel.orderOut(nil)
            window = nil
            return
        }
        let target = offScreenFrame(in: screen)
        let dismissHandler = onDismiss
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = Self.slideDuration * 0.9
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(target, display: true)
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.window = nil
            self?.hostingView = nil
            dismissHandler?()
        })
    }

    // MARK: - Private Helpers

    private func handleJoin(_ url: URL) {
        onJoin?(url)
        hide()
    }

    private func onScreenFrame(in screen: NSScreen) -> NSRect {
        let visible = screen.visibleFrame
        let x = visible.midX - Self.toastWidth / 2
        let y = visible.maxY - Self.toastHeight - Self.topInset
        return NSRect(x: x, y: y, width: Self.toastWidth, height: Self.toastHeight)
    }

    private func offScreenFrame(in screen: NSScreen) -> NSRect {
        let onScreen = onScreenFrame(in: screen)
        return NSRect(x: onScreen.origin.x,
                      y: screen.frame.maxY + 4,
                      width: onScreen.width,
                      height: onScreen.height)
    }
}
