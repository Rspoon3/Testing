//
//  OrderItemViewModel.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// View model for displaying individual order item details.
@Observable
class OrderItemViewModel {
    let item: OrderItem
    private let user: User

    // MARK: - Initializer

    /// Creates an order item view model.
    /// - Parameters:
    ///   - item: The order item to display.
    ///   - user: The user who owns this order item.
    init(item: OrderItem, user: User) {
        self.item = item
        self.user = user
    }

    // MARK: - Public Helpers

    /// Gets the total price for this item.
    /// - Returns: The calculated total price.
    func totalPrice() -> Double {
        item.totalPrice
    }

    /// Formats the unit price.
    /// - Returns: A formatted price string.
    func formattedUnitPrice() -> String {
        String(format: "$%.2f", item.price)
    }

    /// Formats the total price.
    /// - Returns: A formatted total price string.
    func formattedTotalPrice() -> String {
        String(format: "$%.2f", totalPrice())
    }

    /// Gets the user's name who owns this item.
    /// - Returns: The user's name.
    func getUserName() -> String {
        user.name
    }

    /// Gets the user's email who owns this item.
    /// - Returns: The user's email.
    func getUserEmail() -> String {
        user.email
    }

    /// Gets the user's shipping address.
    /// - Returns: The user's address.
    func getUserAddress() -> String {
        user.address
    }
}
