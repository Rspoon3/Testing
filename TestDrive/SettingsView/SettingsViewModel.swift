//
//  SettingsViewModel.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 6/5/26.
//

import Foundation

/// Backs the settings screen, exposing the selectable user identifiers.
@MainActor
@Observable
final class SettingsViewModel {
    /// The user identifiers that can be selected.
    let userIDs = ReferralCodeStore.userIDs

    /// The currently selected user identifier. Persisted to the store on change.
    var selectedUserID: String {
        didSet { store.userID = selectedUserID }
    }

    /// The store that owns the active user identifier.
    private let store: ReferralCodeStore

    // MARK: - Initializer

    /// Creates a new `SettingsViewModel`, seeding the selection from the store.
    /// - Parameter store: The store that owns the active user identifier. Defaults to the shared store.
    init(store: ReferralCodeStore = .shared) {
        self.store = store
        selectedUserID = store.userID
    }
}
