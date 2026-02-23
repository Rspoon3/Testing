import Foundation
import Observation

/// Observable session manager that holds the unlocked `EnvelopeStore`.
///
/// On background, the store is nilled out so `CryptoKit.SymmetricKey`
/// zeroes its memory on deallocation. On foreground, the user must
/// explicitly unlock again.
@Observable
final class EncryptionSession {
    /// The active envelope store, or `nil` when locked.
    private(set) var store: EnvelopeStore?

    /// Whether the session currently holds an unlocked store.
    var isUnlocked: Bool { store != nil }

    // MARK: - Public Helpers

    /// Destroys the in-memory store, zeroing the ARK on deallocation.
    func lock() {
        store = nil
    }

    /// Bootstraps or unlocks the primary envelope store.
    ///
    /// Re-runs the device-unlock flow (biometric prompt) and creates
    /// a fresh `EnvelopeStore` with the recovered ARK.
    func unlock() throws {
        store = try EnvelopeEncryptionDemo.createPrimaryStore()
    }
}
