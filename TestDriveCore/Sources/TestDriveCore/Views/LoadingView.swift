import SwiftUI

/// A reusable loading view with optional message.
///
/// Displays a progress indicator with an optional descriptive message.
public struct LoadingView: View {

    private let message: String?

    // MARK: - Initializer

    /// Creates a new loading view.
    ///
    /// - Parameter message: Optional loading message to display.
    public init(message: String? = nil) {
        self.message = message
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Loading") {
    LoadingView()
}

#Preview("Loading with Message") {
    LoadingView(message: "Loading vaults...")
}
