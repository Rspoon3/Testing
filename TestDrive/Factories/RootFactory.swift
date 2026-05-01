//
//  RootFactory.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// Root factory that manages base-level dependencies and creates user-bound factories.
@Observable
class RootFactory {
    private let imageLoader: ImageLoader
    private let apiClient: APIClient

    // MARK: - Initializer

    /// Creates a root factory with shared services.
    /// - Parameters:
    ///   - imageLoader: The image loader service.
    ///   - apiClient: The API client service.
    init(imageLoader: ImageLoader = ImageLoader(), apiClient: APIClient = APIClient()) {
        self.imageLoader = imageLoader
        self.apiClient = apiClient
    }

    // MARK: - Public Helpers

    /// Creates a user-bound factory using the provided user as a key.
    /// - Parameter user: The user to bind the factory to.
    /// - Returns: A factory that can create user-specific views and view models.
    func makeUserBoundFactory(for user: User) -> UserBoundFactory {
        UserBoundFactory(user: user, rootFactory: self)
    }

    /// Creates a login view model.
    /// - Returns: A new login view model instance.
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(factory: self)
    }

    /// Gets the shared image loader service.
    /// - Returns: The image loader instance.
    func getImageLoader() -> ImageLoader {
        imageLoader
    }

    /// Gets the shared API client service.
    /// - Returns: The API client instance.
    func getAPIClient() -> APIClient {
        apiClient
    }
}
