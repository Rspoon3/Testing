//
//  AsyncCache.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/8/23.
//

import Foundation
import Combine


protocol AsyncCacheProtocol: Actor {
    associatedtype T

    var inProgressCountPublisher: AnyPublisher<Int,Never> { get }
    var fetchedCountPublisher: AnyPublisher<Int,Never> { get }
    
    func clear() async
    func fetch(
        key _key: String,
        action: @escaping () async throws -> T
    ) async throws -> T
}

final actor AsyncCache<T> {
    private let cache = NSCache<NSString, CacheStatusWrapper<T>>()
    private let inProgressCount = CurrentValueSubject<Int, Never>(0)
    private let fetchedCount = CurrentValueSubject<Int, Never>(0)
    
    nonisolated var inProgressCountPublisher: AnyPublisher<Int,Never> {
        inProgressCount.eraseToAnyPublisher()
    }
    
    nonisolated var fetchedCountPublisher: AnyPublisher<Int,Never> {
        fetchedCount.eraseToAnyPublisher()
    }
    
    
    //MARK: - Public
    
    
    func clear() {
        cache.removeAllObjects()
        inProgressCount.send(0)
        fetchedCount.send(0)
    }

    func fetch(
        key _key: String,
        action: @escaping () async throws -> T
    ) async throws -> T {
        let key = _key as NSString
        
        if let wrapper = cache.object(forKey: key) {
            switch wrapper.status {
            case .inProgress(let task):
                return try await task.value
            case .fetched(let image):
                return image
            }
        }

        let task: Task<T, Error> = Task {
            try await action()
        }
        
        cache.setObject(CacheStatusWrapper(.inProgress(task)), forKey: key)
        inProgressCount.value += 1
        
        do {
            let image = try await task.value
            cache.setObject(CacheStatusWrapper(.fetched(image)), forKey: key)
            inProgressCount.value -= 1
            fetchedCount.value += 1
            return image
        } catch {
            throw error
        }
    }
}
