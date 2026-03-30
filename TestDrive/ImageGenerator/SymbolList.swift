import Foundation

/// A curated list of fun SF Symbols suitable for background patterns.
enum SymbolList {
    static let symbols: [String] = [
        "star.fill",
        "heart.fill",
        "bolt.fill",
        "flame.fill",
        "sparkles",
        "moon.fill",
        "sun.max.fill",
        "cloud.fill",
        "snowflake",
        "leaf.fill",
        "drop.fill",
        "pawprint.fill",
        "hare.fill",
        "bird.fill",
        "fish.fill",
        "trophy.fill",
        "crown.fill",
        "diamond.fill",
        "flag.fill",
        "bell.fill",
        "gift.fill",
        "balloon.fill",
        "party.popper.fill",
        "music.note",
        "guitars.fill",
        "gamecontroller.fill",
        "puzzlepiece.fill",
        "atom",
        "globe.americas.fill",
        "airplane",
        "car.fill",
        "bicycle",
        "mountain.2.fill",
        "tree.fill",
        "camera.fill",
        "paintbrush.fill",
        "wand.and.stars",
        "hands.sparkles.fill",
        "face.smiling.fill",
        "cup.and.saucer.fill"
    ]

    /// Returns a random symbol name.
    static func random() -> String {
        symbols.randomElement() ?? "star.fill"
    }
}
