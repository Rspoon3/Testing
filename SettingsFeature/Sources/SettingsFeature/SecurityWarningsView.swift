import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Security warnings screen.
///
/// Displays security concerns including expired keys, rotation reminders,
/// and recent clipboard activity.
public struct SecurityWarningsView: View {

    @State private var viewModel: SecurityWarningsViewModel

    // MARK: - Initializer

    /// Creates a new security warnings view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: SecurityWarningsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.warnings.isEmpty {
                    emptyState
                } else {
                    warningsList
                }
            }
            .navigationTitle("Security")
            .task {
                await viewModel.loadWarnings()
            }
            .refreshable {
                await viewModel.loadWarnings()
            }
        }
    }

    // MARK: - Private Views

    private var emptyState: some View {
        ContentUnavailableView(
            "All Clear",
            systemImage: "checkmark.shield.fill",
            description: Text("No security warnings at this time")
        )
    }

    private var warningsList: some View {
        List {
            ForEach(viewModel.warnings) { warning in
                WarningRowView(warning: warning)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.dismissWarning(warning)
                        } label: {
                            Label("Dismiss", systemImage: "xmark")
                        }
                    }
            }
        }
    }
}

/// Individual warning row view.
struct WarningRowView: View {

    let warning: SecurityWarning

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: warning.severity.icon)
                .foregroundStyle(Color(warning.severity.color))
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(warning.keyLabel)
                    .font(.headline)

                Text(warning.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Private Helpers

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: warning.date, relativeTo: Date())
    }
}

#Preview {
    setupPreviewDependencies()

    let enc = EncryptionService()
    let key = KeychainService()
    let vm = VaultManager(encryption: enc, keychain: key)
    let akm = APIKeyManager(encryption: enc, vaultManager: vm)
    let clip = ClipboardManager()

    return SecurityWarningsView(
        viewModel: SecurityWarningsViewModel(
            apiKeyManager: akm,
            clipboardManager: clip
        )
    )
}
