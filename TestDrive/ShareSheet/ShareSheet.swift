//
//  ShareSheet.swift
//  TestDrive
//

import SwiftUI
import UIKit

/// A SwiftUI wrapper for UIActivityViewController to present a native share sheet.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    // MARK: - Initializer

    /// Creates a new share sheet.
    /// - Parameter items: The items to share (images, text, URLs, etc.).
    init(items: [Any]) {
        self.items = items
    }

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
