import SwiftUI

/// View model for the image generator screen.
@Observable
final class ImageGeneratorViewModel {
    var selectedStyle: BackgroundStyle = .purplePlus {
        didSet {
            resetColors()
            if !selectedStyle.supportsSymbolOverlay {
                symbolName = nil
            }
        }
    }

    var seed: Int = Int.random(in: 0...99999)
    var colorSlots: [ColorSlot] = BackgroundStyle.purplePlus.defaultColors
    var symbolName: String?
    var isSaving = false
    var showSavedAlert = false
    var saveError: String?

    /// The raw color values to pass to the canvas.
    var colorValues: [Color] {
        colorSlots.map(\.color)
    }

    /// Whether the current style supports SF Symbol overlay.
    var showSymbolControls: Bool {
        selectedStyle.supportsSymbolOverlay
    }

    /// Randomizes the seed to generate a new variation.
    func randomize() {
        seed = Int.random(in: 0...99999)
    }

    /// Resets colors to defaults for the current style.
    func resetColors() {
        colorSlots = selectedStyle.defaultColors
    }

    /// Toggles the SF Symbol overlay on or off.
    func toggleSymbol() {
        if symbolName != nil {
            symbolName = nil
        } else {
            symbolName = SymbolList.random()
        }
    }

    /// Picks a new random SF Symbol.
    func shuffleSymbol() {
        symbolName = SymbolList.random()
    }

    /// Renders the current background as a 16:9 UIImage and saves to the photo library.
    @MainActor
    func saveImage() {
        isSaving = true
        let width: CGFloat = 640
        let height: CGFloat = 360

        let canvas = BackgroundCanvasView(
            style: selectedStyle,
            seed: seed,
            colors: colorValues,
            symbolName: symbolName
        )
        .frame(width: width, height: height)

        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 3
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
