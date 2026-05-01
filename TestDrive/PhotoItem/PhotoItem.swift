//
//  PhotoItem.swift
//  TestDrive
//

import SwiftUI
import PhotosUI

/// Represents a photo item with an image, filename, and ranking position.
struct PhotoItem: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let filename: String
    var rank: Int = 0

    // MARK: - Initializer

    /// Creates a new PhotoItem.
    /// - Parameters:
    ///   - image: The UIImage to display.
    ///   - filename: The name of the photo file. Defaults to "Untitled Photo".
    init(image: UIImage, filename: String = "Untitled Photo") {
        self.image = image
        self.filename = filename
        self.rank = 0
    }
}
