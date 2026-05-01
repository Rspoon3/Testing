//
//  LoginViewModel.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// View model for handling user login.
@Observable
class LoginViewModel {
    private let factory: RootFactory

    var name: String = ""
    var email: String = ""
    var userBoundFactory: UserBoundFactory?

    // MARK: - Initializer

    /// Creates a login view model.
    /// - Parameter factory: The root factory for creating user-bound factories.
    init(factory: RootFactory) {
        self.factory = factory
    }

    // MARK: - Public Helpers

    /// Attempts to log in the user with the provided credentials.
    /// Creates a user-bound factory upon successful login.
    func login() {
        guard !name.isEmpty, !email.isEmpty else { return }

        let user = User(name: name, email: email)
        userBoundFactory = factory.makeUserBoundFactory(for: user)
    }

    /// Logs out the current user by clearing the user-bound factory.
    func logout() {
        userBoundFactory = nil
        name = ""
        email = ""
    }
}
