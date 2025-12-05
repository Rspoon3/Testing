import SwiftUI

/// Represents a word in the animated word cloud.
struct OnboardingWord: Identifiable {
    let id = UUID()
    let attitude: Attitude
    var isSelected: Bool = false

    /// Initial position offset for animation.
    var initialOffset: CGSize

    /// Animation phase offset (0-1) to desynchronize animations.
    var animationPhase: Double
}
