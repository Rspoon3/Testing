//
//  User.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// Represents a user in the application.
struct User: Identifiable, Equatable {
    let id: UUID
    let name: String
    let email: String
    let address: String

    /// Creates a new user.
    /// - Parameters:
    ///   - id: Unique identifier for the user.
    ///   - name: The user's display name.
    ///   - email: The user's email address.
    ///   - address: The user's shipping address.
    init(id: UUID = UUID(), name: String, email: String, address: String = "123 Main St, Anytown, USA") {
        self.id = id
        self.name = name
        self.email = email
        self.address = address
    }
}
