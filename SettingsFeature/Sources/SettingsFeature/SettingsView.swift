import SwiftUI
import TestDriveCore
import TestDrivePersistence

/// Settings screen for app configuration.
///
/// Provides controls for clipboard settings, theme preferences, data management,
/// and app information.
public struct SettingsView: View {

    @State private var viewModel: SettingsViewModel
    @State private var showingShareSheet = false

    // MARK: - Initializer

    /// Creates a new settings view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                clipboardSection
                themeSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .alert("Clear All Data", isPresented: $viewModel.showingClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    Task {
                        try? await viewModel.clearAllData()
                    }
                }
            } message: {
                Text("This will permanently delete all vaults and API keys. This action cannot be undone.")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Private Views

    private var clipboardSection: some View {
        Section {
            Picker("Auto-Clear Duration", selection: $viewModel.autoClearDuration) {
                Text("15 seconds").tag(15)
                Text("30 seconds").tag(30)
                Text("1 minute").tag(60)
                Text("5 minutes").tag(300)
                Text("Never").tag(0)
            }
            .onChange(of: viewModel.autoClearDuration) { _, newValue in
                viewModel.updateAutoClearDuration(newValue)
            }

            Toggle("Show Notifications", isOn: $viewModel.notificationsEnabled)
                .onChange(of: viewModel.notificationsEnabled) { _, newValue in
                    viewModel.updateNotificationsEnabled(newValue)
                }

        } header: {
            Text("Clipboard")
        } footer: {
            if viewModel.autoClearDuration == 0 {
                Text("Clipboard will not be cleared automatically. You can still clear it manually from the key detail screen.")
            } else {
                Text("Copied secrets will be automatically cleared from the clipboard after \(formatDuration(viewModel.autoClearDuration)).")
            }
        }
    }

    private var themeSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $viewModel.colorScheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
    }

    private var dataSection: some View {
        Section {
            Button {
                Task {
                    do {
                        let url = try await viewModel.exportData()
                        viewModel.exportURL = url
                        showingShareSheet = true
                    } catch {
                        // Error already set in view model
                    }
                }
            } label: {
                if viewModel.isExporting {
                    HStack {
                        Text("Exporting...")
                        Spacer()
                        ProgressView()
                    }
                } else {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
            }
            .disabled(viewModel.isExporting)

            Button(role: .destructive) {
                viewModel.showingClearConfirmation = true
            } label: {
                if viewModel.isClearing {
                    HStack {
                        Text("Clearing...")
                        Spacer()
                        ProgressView()
                    }
                } else {
                    Label("Clear All Data", systemImage: "trash")
                }
            }
            .disabled(viewModel.isClearing)

        } header: {
            Text("Data Management")
        } footer: {
            Text("Export creates a JSON file with vault and key metadata (secrets are not included). Clear removes all vaults and keys permanently.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(buildNumber)
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://github.com/yourusername/testdrive")!) {
                HStack {
                    Label("GitHub", systemImage: "link")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Private Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
}

/// UIKit share sheet wrapper.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    setupPreviewDependencies()

    let enc = EncryptionService()
    let key = KeychainService()
    let vm = VaultManager(encryption: enc, keychain: key)
    let clip = ClipboardManager()

    return SettingsView(
        viewModel: SettingsViewModel(
            vaultManager: vm,
            clipboardManager: clip
        )
    )
}
