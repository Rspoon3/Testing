//
//  Order.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// Represents a customer order.
struct Order: Identifiable, Hashable {
    let id: UUID
    let orderNumber: String
    let date: Date
    let total: Double
    let status: OrderStatus
    let items: [OrderItem]

    /// Creates a new order.
    /// - Parameters:
    ///   - id: Unique identifier for the order.
    ///   - orderNumber: Human-readable order number.
    ///   - date: Date the order was placed.
    ///   - total: Total cost of the order.
    ///   - status: Current status of the order.
    ///   - items: Items included in the order.
    init(
        id: UUID = UUID(),
        orderNumber: String,
        date: Date,
        total: Double,
        status: OrderStatus,
        items: [OrderItem]
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.date = date
        self.total = total
        self.status = status
        self.items = items
    }
}

/// Order status enumeration.
enum OrderStatus: String, CaseIterable {
    case pending = "Pending"
    case processing = "Processing"
    case shipped = "Shipped"
    case delivered = "Delivered"
    case cancelled = "Cancelled"
}
