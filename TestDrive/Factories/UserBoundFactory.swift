//
//  UserBoundFactory.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// Factory that creates user-specific views and view models.
/// This factory requires a valid user to be created, ensuring compile-time safety.
class UserBoundFactory {
    private let user: User
    private let rootFactory: RootFactory

    // MARK: - Initializer

    /// Creates a user-bound factory.
    /// - Parameters:
    ///   - user: The user this factory is bound to.
    ///   - rootFactory: Reference to the root factory for shared dependencies.
    init(user: User, rootFactory: RootFactory) {
        self.user = user
        self.rootFactory = rootFactory
    }

    // MARK: - Public Helpers

    /// Creates a profile view model for the bound user.
    /// - Returns: A profile view model configured with the user.
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(user: user)
    }

    /// Creates a settings view model for the bound user.
    /// - Returns: A settings view model configured with the user.
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(user: user)
    }

    /// Creates an order history view model for the bound user.
    /// - Returns: An order history view model configured with the user.
    func makeOrderHistoryViewModel() -> OrderHistoryViewModel {
        OrderHistoryViewModel(user: user)
    }

    /// Creates an order-bound factory using the provided order as a key.
    /// - Parameter order: The order to bind the factory to.
    /// - Returns: A factory that can create order-specific views and view models.
    func makeOrderBoundFactory(for order: Order) -> OrderBoundFactory {
        OrderBoundFactory(user: user, order: order, rootFactory: rootFactory)
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
}
