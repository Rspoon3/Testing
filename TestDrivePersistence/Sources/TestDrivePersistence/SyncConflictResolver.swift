import Foundation
import TestDriveCore

/// Handles conflict resolution for iCloud sync.
///
/// SQLiteData provides automatic conflict resolution, but this service
/// provides app-specific conflict resolution strategies.
public final class SyncConflictResolver: Sendable {

    public init() {}

    // MARK: - Conflict Resolution Strategies

    /// Resolves conflicts for Vault records.
    ///
    /// Strategy: Most recent update wins, preserving user intent.
    ///
    /// - Parameters:
    ///   - local: The local version of the vault.
    ///   - remote: The remote version from CloudKit.
    /// - Returns: The resolved vault.
    public func resolveVault(local: Vault, remote: Vault) -> Vault {
        // Use most recent updatedAt timestamp
        if local.updatedAt > remote.updatedAt {
            return local
        } else {
            return remote
        }
    }

    /// Resolves conflicts for APIKey records.
    ///
    /// Strategy: Most recent update wins. If timestamps are equal,
    /// prefer the version with more metadata.
    ///
    /// - Parameters:
    ///   - local: The local version of the key.
    ///   - remote: The remote version from CloudKit.
    /// - Returns: The resolved key.
    public func resolveAPIKey(local: APIKey, remote: APIKey) -> APIKey {
        // If one was updated more recently, use that
        if local.createdAt != remote.createdAt {
            return local.createdAt > remote.createdAt ? local : remote
        }

        // If timestamps are equal, prefer the one with more data
        let localScore = metadataScore(for: local)
        let remoteScore = metadataScore(for: remote)

        return localScore >= remoteScore ? local : remote
    }

    /// Resolves conflicts for VaultParticipant records.
    ///
    /// Strategy: Most recent addedAt timestamp wins.
    ///
    /// - Parameters:
    ///   - local: The local version of the participant.
    ///   - remote: The remote version from CloudKit.
    /// - Returns: The resolved participant.
    public func resolveParticipant(
        local: VaultParticipant,
        remote: VaultParticipant
    ) -> VaultParticipant {
        return local.addedAt > remote.addedAt ? local : remote
    }

    /// Resolves conflicts for WrappedVaultKey records.
    ///
    /// Strategy: Most recent wrappedAt timestamp wins.
    ///
    /// - Parameters:
    ///   - local: The local version of the wrapped key.
    ///   - remote: The remote version from CloudKit.
    /// - Returns: The resolved wrapped key.
    public func resolveWrappedKey(
        local: WrappedVaultKey,
        remote: WrappedVaultKey
    ) -> WrappedVaultKey {
        return local.wrappedAt > remote.wrappedAt ? local : remote
    }

    // MARK: - Private Helpers

    /// Calculates a metadata completeness score for an API key.
    ///
    /// Used to prefer the version with more information in case of ties.
    private func metadataScore(for key: APIKey) -> Int {
        var score = 0

        if key.websiteDomain != nil { score += 1 }
        if key.company != nil { score += 1 }
        if !key.tags.isEmpty { score += key.tags.count }
        if !key.notes.isEmpty { score += 1 }
        if key.rotateAt != nil { score += 1 }
        if key.lastUsedAt != nil { score += 1 }

        return score
    }
}
