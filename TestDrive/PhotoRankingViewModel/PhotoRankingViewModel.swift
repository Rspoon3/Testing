//
//  PhotoRankingViewModel.swift
//  TestDrive
//

import SwiftUI
import PhotosUI

@MainActor
class PhotoRankingViewModel: ObservableObject {
    @Published var selectedPhotos: [PhotoItem] = []
    @Published var isComparing = false
    @Published var showError = false
    @Published var errorMessage = ""

    // MARK: - Public Helpers

    func loadPhotos(from items: [PhotosPickerItem]) async {
        selectedPhotos = []

        for (index, item) in items.enumerated() {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Try to get the filename from itemIdentifier, otherwise use a numbered default
                let filename = item.itemIdentifier ?? "Photo \(index + 1)"
                selectedPhotos.append(PhotoItem(image: image, filename: filename))
            }
        }

        validateAndStartComparison()
    }

    func loadPhotosFromFiles(urls: [URL]) async {
        selectedPhotos = []

        for url in urls {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                let filename = url.lastPathComponent
                selectedPhotos.append(PhotoItem(image: image, filename: filename))
            }
        }

        validateAndStartComparison()
    }

    func reset() {
        selectedPhotos = []
        isComparing = false
    }

    // MARK: - Private Helpers

    /// Validates that at least 2 photos are selected before starting comparison.
    private func validateAndStartComparison() {
        if selectedPhotos.count < 2 {
            errorMessage = "Please select at least 2 photos to compare"
            showError = true
        } else {
            isComparing = true
        }
    }
}