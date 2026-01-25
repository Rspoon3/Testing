import SwiftUI
import CloudKit
import TestDriveCore

/// View for managing vault sharing and participants.
public struct ShareVaultView: View {

    @State private var viewModel: ShareVaultViewModel
    @State private var showingShareSheet = false
    @State private var showingStopSharingAlert = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initializer

    /// Creates a new share vault view.
    ///
    /// - Parameter viewModel: The view model for this view.
    public init(viewModel: ShareVaultViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            List {
                if viewModel.vault.isShared {
                    sharingStatusSection
                    participantsSection
                    stopSharingSection
                } else {
                    notSharedSection
                }
            }
            .navigationTitle("Share Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadParticipants()
            }
            .alert("Stop Sharing", isPresented: $showingStopSharingAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Stop Sharing", role: .destructive) {
                    stopSharing()
                }
            } message: {
                Text("This will remove access for all participants. They will no longer be able to view or decrypt keys in this vault.")
            }
        }
    }

    // MARK: - Private Views

    private var notSharedSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "person.2.badge.key")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Share This Vault")
                    .font(.headline)

                Text("Share this vault with other iCloud users. All API keys will be accessible to participants with end-to-end encryption.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    shareVault()
                } label: {
                    Label("Share Vault", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
        }
    }

    private var sharingStatusSection: some View {
        Section {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Vault Shared")
                        .font(.headline)

                    Text("\(viewModel.participants.count) \(viewModel.participants.count == 1 ? "participant" : "participants")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var participantsSection: some View {
        Section("Participants") {
            ForEach(viewModel.participants) { participant in
                ParticipantRowView(
                    participant: participant,
                    onUpdatePermission: { permission in
                        Task {
                            try? await viewModel.updatePermission(for: participant, to: permission)
                        }
                    },
                    onRemove: {
                        Task {
                            try? await viewModel.removeParticipant(participant)
                        }
                    }
                )
            }
        }
    }

    private var stopSharingSection: some View {
        Section {
            Button(role: .destructive) {
                showingStopSharingAlert = true
            } label: {
                Label("Stop Sharing", systemImage: "person.2.slash")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Private Helpers

    private func shareVault() {
        Task {
            do {
                _ = try await viewModel.shareVault()
                // In production, present UICloudSharingController here
                await viewModel.loadParticipants()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }

    private func stopSharing() {
        Task {
            try? await viewModel.stopSharing()
            dismiss()
        }
    }
}

#Preview {
    let db = try! DatabaseManager(enableSync: false)
    let enc = EncryptionService()
    let key = KeychainService()
    let vm = VaultManager(database: db, encryption: enc, keychain: key)

    return ShareVaultView(
        viewModel: ShareVaultViewModel(
            vault: Vault(
                name: "Work APIs",
                iconName: "briefcase.fill",
                colorHex: "#007AFF",
                ownerPublicKey: Data(),
                isShared: true
            ),
            vaultManager: vm,
            database: db
        )
    )
}
