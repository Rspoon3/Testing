//
//  VoidCache.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/8/23.
//

import Foundation
import Combine

final actor VoidCache: AsyncCacheProtocol {
    private let asyncCache = AsyncCache<Void>()
    static let shared = VoidCache()
    
    nonisolated var inProgressCountPublisher: AnyPublisher<Int,Never> {
        asyncCache.inProgressCountPublisher
    }
    
    nonisolated var fetchedCountPublisher: AnyPublisher<Int,Never> {
        asyncCache.fetchedCountPublisher
    }
    
    private init() {}
    
    func clear() async {
        await asyncCache.clear()
    }
    
    func fetch(
        key _key: String,
        action: @escaping () async throws -> Void
    ) async throws -> Void {
        try await asyncCache.fetch(key: _key, action: action)
    }
}
