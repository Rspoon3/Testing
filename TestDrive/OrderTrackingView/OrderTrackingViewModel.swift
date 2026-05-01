//
//  OrderTrackingViewModel.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// View model for tracking an order's shipping status.
/// This view model can ONLY be created through OrderBoundFactory, ensuring both User and Order are available.
@Observable
class OrderTrackingViewModel {
    private let user: User
    private let order: Order
    private let apiClient: APIClient

    var trackingNumber: String
    var estimatedDelivery: Date
    var currentLocation: String

    // MARK: - Initializer

    /// Creates an order tracking view model.
    /// - Parameters:
    ///   - user: The user who owns this order.
    ///   - order: The order to track.
    ///   - apiClient: The API client for fetching tracking updates.
    init(user: User, order: Order, apiClient: APIClient) {
        self.user = user
        self.order = order
        self.apiClient = apiClient

        // Simulate tracking data
        self.trackingNumber = "TRK\(order.orderNumber)"
        self.estimatedDelivery = order.date.addingTimeInterval(86400 * 5)
        self.currentLocation = "Distribution Center - Los Angeles, CA"
    }

    // MARK: - Public Helpers

    /// Gets the order number.
    /// - Returns: The order number.
    func getOrderNumber() -> String {
        order.orderNumber
    }

    /// Gets the user's name.
    /// - Returns: The user's name.
    func getUserName() -> String {
        user.name
    }

    /// Gets the user's shipping address.
    /// - Returns: The user's address.
    func getShippingAddress() -> String {
        user.address
    }

    /// Formats the estimated delivery date.
    /// - Returns: A formatted date string.
    func formattedEstimatedDelivery() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: estimatedDelivery)
    }

    /// Refreshes tracking information from the API.
    func refreshTracking() async {
        // In a real app, this would fetch from the API
        // For demo purposes, just simulate a delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        currentLocation = "Out for Delivery - \(user.address.split(separator: ",").last?.trimmingCharacters(in: .whitespaces) ?? "Unknown")"
    }
}
