//
//  OrderDetailViewModel.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// View model for displaying order details.
@Observable
class OrderDetailViewModel {
    let order: Order
    private let user: User

    // MARK: - Initializer

    /// Creates an order detail view model.
    /// - Parameters:
    ///   - order: The order to display details for.
    ///   - user: The user who owns this order.
    init(order: Order, user: User) {
        self.order = order
        self.user = user
    }

    // MARK: - Public Helpers

    /// Formats the order date.
    /// - Returns: A formatted date string.
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: order.date)
    }

    /// Calculates the subtotal of all items.
    /// - Returns: The subtotal amount.
    func calculateSubtotal() -> Double {
        order.items.reduce(0) { $0 + $1.totalPrice }
    }

    /// Calculates tax amount (10% for demo).
    /// - Returns: The tax amount.
    func calculateTax() -> Double {
        calculateSubtotal() * 0.1
    }

    /// Creates an order item view model for a specific item.
    /// - Parameter item: The order item to create a view model for.
    /// - Returns: An order item view model configured with the item and user.
    func makeOrderItemViewModel(for item: OrderItem) -> OrderItemViewModel {
        OrderItemViewModel(item: item, user: user)
    }

    /// Gets the order for creating order-bound factories.
    /// - Returns: The current order.
    func getOrder() -> Order {
        order
    }

    /// Gets the user for creating order-bound factories.
    /// - Returns: The current user.
    func getUser() -> User {
        user
    }
}
