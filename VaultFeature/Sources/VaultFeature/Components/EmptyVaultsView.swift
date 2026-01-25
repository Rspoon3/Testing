import SwiftUI

/// Empty state view when no vaults exist.
struct EmptyVaultsView: View {

    // MARK: - Body

    var body: some View {
        ContentUnavailableView {
            Label("No Vaults", systemImage: "lock.slash")
        } description: {
            Text("Create a vault to start storing API keys securely")
        }
    }
}

#Preview {
    EmptyVaultsView()
}
