//
//  OrderHistoryViewModel.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// View model for displaying user order history.
@Observable
class OrderHistoryViewModel {
    private let user: User

    let orders: [Order]

    // MARK: - Initializer

    /// Creates an order history view model.
    /// - Parameter user: The user whose orders to display.
    init(user: User) {
        self.user = user
        // Generate sample orders for the user
        self.orders = Self.generateSampleOrders(for: user)
    }

    // MARK: - Public Helpers

    /// Gets the user's name for display.
    /// - Returns: The user's name.
    func getUserName() -> String {
        user.name
    }

    /// Creates an order detail view model for a specific order.
    /// - Parameter order: The order to create a view model for.
    /// - Returns: An order detail view model configured with the order and user.
    func makeOrderDetailViewModel(for order: Order) -> OrderDetailViewModel {
        OrderDetailViewModel(order: order, user: user)
    }

    /// Gets the user for creating factories.
    /// - Returns: The current user.
    func getUser() -> User {
        user
    }

    // MARK: - Private Helpers

    /// Generates sample order data for demonstration.
    /// - Parameter user: The user to generate orders for.
    /// - Returns: An array of sample orders.
    private static func generateSampleOrders(for user: User) -> [Order] {
        [
            Order(
                orderNumber: "ORD-001",
                date: Date().addingTimeInterval(-86400 * 7),
                total: 129.99,
                status: .delivered,
                items: [
                    OrderItem(productName: "Wireless Headphones", quantity: 1, price: 79.99),
                    OrderItem(productName: "Phone Case", quantity: 2, price: 25.00)
                ]
            ),
            Order(
                orderNumber: "ORD-002",
                date: Date().addingTimeInterval(-86400 * 3),
                total: 49.99,
                status: .shipped,
                items: [
                    OrderItem(productName: "USB-C Cable", quantity: 1, price: 19.99),
                    OrderItem(productName: "Screen Protector", quantity: 3, price: 10.00)
                ]
            ),
            Order(
                orderNumber: "ORD-003",
                date: Date().addingTimeInterval(-86400),
                total: 299.99,
                status: .processing,
                items: [
                    OrderItem(productName: "Mechanical Keyboard", quantity: 1, price: 149.99),
                    OrderItem(productName: "Gaming Mouse", quantity: 1, price: 89.99),
                    OrderItem(productName: "Mouse Pad", quantity: 2, price: 30.00)
                ]
            )
        ]
    }
}
