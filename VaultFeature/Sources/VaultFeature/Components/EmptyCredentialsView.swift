import SwiftUI

/// Empty state view when no credentials exist in the vault.
struct EmptyCredentialsView: View {

    // MARK: - Body

    var body: some View {
        ContentUnavailableView {
            Label("No Credentials", systemImage: "key.slash")
        } description: {
            Text("Add your first credential to this vault")
        }
    }
}

#Preview {
    EmptyCredentialsView()
}
