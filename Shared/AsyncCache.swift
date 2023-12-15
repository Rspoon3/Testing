//
//  AsyncCache.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/15/23.
//

import Foundation


public final actor AsyncCache<KeyType: Hashable & Sendable & NSObject, ObjectType: Sendable> {
    private let cache = NSCache<KeyType, CacheStatusWrapper<ObjectType>>()
    
    //MARK: - Initializer
    init() {}
    
    
    //MARK: - Public
    func clear() {
        cache.removeAllObjects()
    }

    public func fetch(
        key: KeyType,
        action: @escaping @Sendable () async throws -> ObjectType
    ) async throws -> ObjectType {
        
        if let wrapper = cache.object(forKey: key) {
            switch wrapper.status {
            case .inProgress(let task):
                return try await task.value
            case .fetched(let image):
                return image
            }
        }

        let task = Task {
            try await action()
        }
        
        cache.setObject(CacheStatusWrapper(.inProgress(task)), forKey: key)
        
        do {
            let image = try await task.value
            cache.setObject(CacheStatusWrapper(.fetched(image)), forKey: key)
            return image
        } catch {
            throw error
        }
    }
}
