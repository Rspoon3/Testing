//
//  AsyncCache.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/15/23.
//

import Foundation

public final actor AsyncCache<KeyType: Hashable & Sendable, ObjectType: Sendable> {
    private(set) var cache: [KeyType: CacheStatus<ObjectType>] = [:]
    var continuations = [KeyType: CheckedContinuation<ObjectType, Error>]()
    
    public func set(values: [(key: KeyType, value: ObjectType)]) {
        for item in values {
            setValue(item.value, forKey: item.key)
        }
    }

    func setValue(_ value: ObjectType, forKey key: KeyType) {
        cache[key] = .fetched(value)
        continuations[key]?.resume(returning: value)
        continuations.removeValue(forKey: key)
    }
    
    func value(for input: KeyType) async throws -> ObjectType {
        if let status = cache[input] {
            switch status {
            case .fetched(let value):
                return value
            case .inProgress(let task):
                print("must be a single")
                return try await task.value
            }
        } else {
            let task = Task {
                try await withTaskCancellationHandler {
                    try await withCheckedThrowingContinuation {
                        continuations.updateValue($0, forKey: input)
                    }
                } onCancel: {
                    Task {
                        await cancelContinuation(input: input)
                    }
                }
            }
            
            cache[input] = .inProgress(task)
            return try await task.value
        }
    }
    
    public func value(
        key: KeyType,
        action: @escaping @Sendable () async throws -> ObjectType
    ) async throws -> ObjectType {
        
        if let status = cache[key] {
            switch status {
            case .fetched(let value):
                return value
            case .inProgress(let task):
                return try await task.value
            }
        }

        let task = Task {
            try await action()
        }
        
        cache[key] = .inProgress(task)
        let value = try await task.value
        cache[key] = .fetched(value)

        return value
    }
    
    func cancelContinuations(ids: Set<KeyType>) {
        for id in ids {
            cancelContinuation(input: id)
        }
    }
    
    private func cancelContinuation(input: KeyType) {
        continuations[input]?.resume(throwing: CancellationError())
        continuations.removeValue(forKey: input)
    }
}
