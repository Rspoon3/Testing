//
//  AsyncSingleChannel.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/15/23.
//

import Foundation

public final actor AsyncSingleChannel<KeyType: Hashable & Sendable, ObjectType: Sendable> {
    private var cache: [KeyType: CacheStatus<ObjectType>] = [:]
    var continuations = [KeyType: CheckedContinuation<ObjectType, Error>]()

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
