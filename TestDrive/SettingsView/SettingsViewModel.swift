//
//  SettingsViewModel.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// View model for managing user settings.
@Observable
class SettingsViewModel {
    private let user: User

    var notificationsEnabled: Bool = true
    var darkModeEnabled: Bool = false

    // MARK: - Initializer

    /// Creates a settings view model.
    /// - Parameter user: The user whose settings to manage.
    init(user: User) {
        self.user = user
    }

    // MARK: - Public Helpers

    /// Gets the user's display name for personalization.
    /// - Returns: The user's name.
    func getUserName() -> String {
        user.name
    }

    /// Saves the current settings (placeholder for persistence logic).
    func saveSettings() {
        // In a real app, this would save to UserDefaults, a database, etc.
    }
}
