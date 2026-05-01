//
//  OrderBoundFactory.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// Factory that creates order-specific views and view models.
/// This factory requires both a valid user AND a valid order to be created, ensuring compile-time safety.
class OrderBoundFactory: Hashable {
    private let user: User
    private let order: Order
    private let rootFactory: RootFactory

    // MARK: - Initializer

    /// Creates an order-bound factory.
    /// - Parameters:
    ///   - user: The user this factory is bound to.
    ///   - order: The order this factory is bound to.
    ///   - rootFactory: Reference to the root factory for shared dependencies.
    init(user: User, order: Order, rootFactory: RootFactory) {
        self.user = user
        self.order = order
        self.rootFactory = rootFactory
    }

    // MARK: - Public Helpers

    /// Creates an order tracking view model for the bound order.
    /// - Returns: An order tracking view model configured with the user and order.
    func makeOrderTrackingViewModel() -> OrderTrackingViewModel {
        OrderTrackingViewModel(
            user: user,
            order: order,
            apiClient: rootFactory.getAPIClient()
        )
    }

    /// Gets the shared image loader service from the root factory.
    /// - Returns: The image loader instance.
    func getImageLoader() -> ImageLoader {
        rootFactory.getImageLoader()
    }

    /// Gets the shared API client service from the root factory.
    /// - Returns: The API client instance.
    func getAPIClient() -> APIClient {
        rootFactory.getAPIClient()
    }

    // MARK: - Hashable

    static func == (lhs: OrderBoundFactory, rhs: OrderBoundFactory) -> Bool {
        lhs.user.id == rhs.user.id && lhs.order.id == rhs.order.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(user.id)
        hasher.combine(order.id)
    }
}
