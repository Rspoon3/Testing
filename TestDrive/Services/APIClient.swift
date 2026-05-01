//
//  APIClient.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// Service for making API requests.
class APIClient {
    private let urlSession: URLSession
    private let baseURL: URL

    // MARK: - Initializer

    /// Creates an API client.
    /// - Parameters:
    ///   - urlSession: The URL session to use for network requests.
    ///   - baseURL: The base URL for API requests.
    init(urlSession: URLSession = .shared, baseURL: URL = URL(string: "https://api.example.com")!) {
        self.urlSession = urlSession
        self.baseURL = baseURL
    }

    // MARK: - Public Helpers

    /// Fetches user orders from the API.
    /// - Parameter userId: The user's ID.
    /// - Returns: Array of orders.
    func fetchOrders(for userId: UUID) async throws -> [Order] {
        // In a real app, this would make an actual API request
        // For demo purposes, we'll just return empty array
        []
    }

    /// Updates order status via API.
    /// - Parameters:
    ///   - orderId: The order's ID.
    ///   - status: The new status.
    func updateOrderStatus(orderId: UUID, status: OrderStatus) async throws {
        // In a real app, this would make an actual API request
        print("Updating order \(orderId) to status: \(status.rawValue)")
    }

    /// Simulates checking API availability.
    /// - Returns: Whether the API is available.
    func checkAvailability() -> Bool {
        true
    }
}
