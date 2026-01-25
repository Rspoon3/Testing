import UIKit

/// Manages haptic feedback throughout the app.
///
/// Provides consistent haptic feedback for user interactions to enhance
/// the user experience with tactile responses.
public final class HapticFeedbackManager: Sendable {

    public init() {}

    // MARK: - Public Helpers

    /// Triggers a light impact haptic (for selections, taps).
    public func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Triggers a medium impact haptic (for important actions).
    public func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Triggers a heavy impact haptic (for critical actions).
    public func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Triggers a success haptic (for completed actions).
    public func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Triggers a warning haptic (for warnings or caution).
    public func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Triggers an error haptic (for errors or failures).
    public func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Triggers a selection haptic (for picker changes, toggles).
    public func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// Prepares the haptic engine for an upcoming interaction.
    ///
    /// Call this before triggering haptic to reduce latency.
    /// - Parameter style: The impact style to prepare.
    public func prepare(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
    }
}
