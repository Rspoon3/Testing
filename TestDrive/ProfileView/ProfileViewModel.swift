//
//  ProfileViewModel.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// View model for displaying user profile information.
@Observable
class ProfileViewModel {
    private let user: User

    // MARK: - Initializer

    /// Creates a profile view model.
    /// - Parameter user: The user whose profile to display.
    init(user: User) {
        self.user = user
    }

    // MARK: - Public Helpers

    /// Gets the user's display name.
    /// - Returns: The user's name.
    func getUserName() -> String {
        user.name
    }

    /// Gets the user's email address.
    /// - Returns: The user's email.
    func getUserEmail() -> String {
        user.email
    }

    /// Gets the user's unique identifier.
    /// - Returns: The user's ID as a string.
    func getUserID() -> String {
        user.id.uuidString
    }
}
