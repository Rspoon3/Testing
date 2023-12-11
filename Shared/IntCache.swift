//
//  IntCache.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/11/23.
//

import Foundation
import Combine

final actor IntCache: AsyncCacheProtocol {
    private let asyncCache = AsyncCache<Int>()
    static let shared = IntCache()
    
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
        action: @escaping () async throws -> Int
    ) async throws -> Int {
        try await asyncCache.fetch(key: _key, action: action)
    }
}
