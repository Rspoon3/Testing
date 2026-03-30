import SwiftUI

/// View model for the image generator screen.
@Observable
final class ImageGeneratorViewModel {
    var selectedStyle: BackgroundStyle = .purplePlus
    var seed: Int = Int.random(in: 0...99999)
    var isSaving = false
    var showSavedAlert = false
    var saveError: String?

    /// Randomizes the seed to generate a new variation.
    func randomize() {
        seed = Int.random(in: 0...99999)
    }

    /// Renders the current background as a 16:9 UIImage and saves to the photo library.
    @MainActor
    func saveImage() {
        isSaving = true
        let width: CGFloat = 1920
        let height: CGFloat = 1080

        let canvas = BackgroundCanvasView(style: selectedStyle, seed: seed)
            .frame(width: width, height: height)

        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: width, height: height)

        guard let uiImage = renderer.uiImage else {
            saveError = "Failed to render image"
            isSaving = false
            return
        }

        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        isSaving = false
        showSavedAlert = true
    }
}
