//
//  ImageLoader.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// Service for loading and caching images.
class ImageLoader {
    private let urlSession: URLSession

    // MARK: - Initializer

    /// Creates an image loader.
    /// - Parameter urlSession: The URL session to use for network requests.
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    // MARK: - Public Helpers

    /// Loads an image from a URL.
    /// - Parameter url: The URL to load the image from.
    /// - Returns: Image data if successful.
    func loadImage(from url: URL) async throws -> Data {
        let (data, _) = try await urlSession.data(from: url)
        return data
    }

    /// Simulates loading a placeholder image.
    /// - Returns: Placeholder text for demonstration.
    func loadPlaceholder() -> String {
        "📦 Image placeholder"
    }
}
