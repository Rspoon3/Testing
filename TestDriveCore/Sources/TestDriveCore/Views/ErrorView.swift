import SwiftUI

/// A reusable error view with retry functionality.
///
/// Displays error messages in a consistent format with an optional retry button.
public struct ErrorView: View {

    private let title: String
    private let message: String
    private let retryAction: (() -> Void)?

    // MARK: - Initializer

    /// Creates a new error view.
    ///
    /// - Parameters:
    ///   - title: The error title.
    ///   - message: The detailed error message.
    ///   - retryAction: Optional retry action closure.
    public init(
        title: String = "Something Went Wrong",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    // MARK: - Body

    public var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(message)
        } actions: {
            if let retryAction = retryAction {
                Button("Try Again") {
                    retryAction()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    ErrorView(
        message: "Failed to load vaults. Please check your network connection.",
        retryAction: {
            print("Retry tapped")
        }
    )
}
