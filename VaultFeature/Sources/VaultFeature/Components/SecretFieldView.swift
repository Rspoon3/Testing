import SwiftUI

/// View for displaying a secret with show/hide functionality.
struct SecretFieldView: View {

    let secret: String?
    let isVisible: Bool
    let isLoading: Bool
    let onToggleVisibility: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            if isLoading {
                ProgressView()
            } else if let secret {
                Text(isVisible ? secret : maskedSecret)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("••••••••••••••••")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                onToggleVisibility()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Private Helpers

    private var maskedSecret: String {
        guard let secret else { return "" }
        return String(repeating: "•", count: min(secret.count, 20))
    }
}

#Preview {
    List {
        Section("Visible") {
            SecretFieldView(
                secret: "sk-test-1234567890abcdef",
                isVisible: true,
                isLoading: false,
                onToggleVisibility: {}
            )
        }

        Section("Hidden") {
            SecretFieldView(
                secret: "sk-test-1234567890abcdef",
                isVisible: false,
                isLoading: false,
                onToggleVisibility: {}
            )
        }

        Section("Loading") {
            SecretFieldView(
                secret: nil,
                isVisible: false,
                isLoading: true,
                onToggleVisibility: {}
            )
        }
    }
}
