//
//  OrderItem.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// Represents an item within an order.
struct OrderItem: Identifiable, Hashable {
    let id: UUID
    let productName: String
    let quantity: Int
    let price: Double
    let imageURL: String?

    /// Creates a new order item.
    /// - Parameters:
    ///   - id: Unique identifier for the item.
    ///   - productName: Name of the product.
    ///   - quantity: Quantity ordered.
    ///   - price: Price per unit.
    ///   - imageURL: Optional URL to product image.
    init(
        id: UUID = UUID(),
        productName: String,
        quantity: Int,
        price: Double,
        imageURL: String? = nil
    ) {
        self.id = id
        self.productName = productName
        self.quantity = quantity
        self.price = price
        self.imageURL = imageURL
    }

    // MARK: - Public Helpers

    /// Calculates the total price for this item.
    /// - Returns: The total price (quantity * price).
    var totalPrice: Double {
        Double(quantity) * price
    }
}
