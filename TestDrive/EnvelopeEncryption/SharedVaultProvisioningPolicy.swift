import Foundation

/// Share participant roles used by the shared-vault provisioning model.
enum VaultShareRole {
    /// Full authority over membership and key rotation.
    case owner
    /// Can edit vault data and provision participants/devices, but not membership/rotation.
    case writer
    /// Read-only role; can only self-provision devices.
    case viewer
}

/// Authorization rules for shared-vault key provisioning operations.
///
/// This layer mirrors the policy used by the envelope architecture sample
/// without coupling to CloudKit APIs.
enum SharedVaultProvisioningPolicy {
    /// Returns `true` when actor can wrap/distribute a vault key for the target principal.
    ///
    /// Owners and writers can provision anyone. Viewers can only self-provision.
    static func canProvision(
        actorRole: VaultShareRole,
        actorPrincipalID: UUID,
        targetPrincipalID: UUID
    ) -> Bool {
        if actorRole == .owner || actorRole == .writer {
            return true
        }
        return actorPrincipalID == targetPrincipalID
    }

    /// Returns `true` only for owners.
    static func canModifyMembership(actorRole: VaultShareRole) -> Bool {
        actorRole == .owner
    }

    /// Returns `true` only for owners.
    static func canRotateVaultKey(actorRole: VaultShareRole) -> Bool {
        actorRole == .owner
    }
}
