import SwiftUI

/// Empty state view when no keys exist in the vault.
struct EmptyKeysView: View {

    // MARK: - Body

    var body: some View {
        ContentUnavailableView {
            Label("No API Keys", systemImage: "key.slash")
        } description: {
            Text("Add your first API key to this vault")
        }
    }
}

#Preview {
    EmptyKeysView()
}
