//
//  SettingsViewModelTests.swift
//  TestDriveTests
//
//  Created by Ricky Witherspoon on 6/9/26.
//

import Testing
@testable import TestDrive

@MainActor
@Suite("Settings View Model Tests")
struct SettingsViewModelTests {
    @Test("The selection is seeded from the store's current user")
    func seedsFromStore() {
        let store = ReferralCodeStore(defaults: .makeEphemeral())
        store.userID = "user-789"

        let viewModel = SettingsViewModel(store: store)

        #expect(viewModel.selectedUserID == "user-789")
    }

    @Test("Changing the selection updates the store")
    func changingSelectionUpdatesStore() {
        let store = ReferralCodeStore(defaults: .makeEphemeral())
        let viewModel = SettingsViewModel(store: store)

        viewModel.selectedUserID = "user-456"

        #expect(store.userID == "user-456")
    }

    @Test("It exposes the selectable user identifiers")
    func exposesSelectableUserIDs() {
        let viewModel = SettingsViewModel(store: ReferralCodeStore(defaults: .makeEphemeral()))

        #expect(viewModel.userIDs == ReferralCodeStore.userIDs)
    }
}
