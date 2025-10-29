import SwiftUI

/// A button style that provides sensory feedback when the button is pressed.
///
/// This style can be applied to any button to automatically trigger haptic feedback
/// without needing to add `.sensoryFeedback` to each button individually.
///
/// Example usage:
/// ```swift
/// Button("Press Me") {
///     print("Button pressed")
/// }
/// .buttonStyle(.haptic)
/// ```
///
/// You can also apply it globally in your app:
/// ```swift
/// WindowGroup {
///     ContentView()
///         .buttonStyle(.haptic)
/// }
/// ```
struct HapticButtonStyle: ButtonStyle {
    /// The type of sensory feedback to provide.
    private let feedback: SensoryFeedback

    // MARK: - Initializer

    /// Creates a new haptic button style.
    /// - Parameter feedback: The type of sensory feedback to trigger. Defaults to `.impact`.
    init(feedback: SensoryFeedback = .impact) {
        self.feedback = feedback
    }
    
    // MARK: - Body
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.accentColor)
            .sensoryFeedback(feedback, trigger: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

// MARK: - Convenience Extension

extension ButtonStyle where Self == HapticButtonStyle {
    /// A button style that provides haptic feedback.
    static var haptic: HapticButtonStyle {
        HapticButtonStyle()
    }

    /// A button style that provides haptic feedback with a custom feedback type.
    /// - Parameter feedback: The type of sensory feedback to trigger.
    /// - Returns: A haptic button style with the specified feedback.
    static func haptic(_ feedback: SensoryFeedback) -> HapticButtonStyle {
        HapticButtonStyle(feedback: feedback)
    }
}

// MARK: - View Extension

extension View {
    /// Applies haptic button style to buttons in this view.
    ///
    /// This is syntactic sugar for `.buttonStyle(.haptic)`.
    ///
    /// Example:
    /// ```swift
    /// Button("Tap Me") {
    ///     print("Tapped")
    /// }
    /// .hapticButtonStyle()
    /// ```
    ///
    /// - Parameter feedback: The type of sensory feedback to trigger. Defaults to `.impact`.
    /// - Returns: A view with haptic button style applied.
    func hapticButtonStyle(_ feedback: SensoryFeedback = .impact) -> some View {
        buttonStyle(.haptic(feedback))
    }
}
