//
//  InMemoryStore.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//

import Foundation
import Combine
import os.lock

public class InMemoryStore<T: Sendable> {
    private let lock = OSAllocatedUnfairLock()
    private var _value: T
    private let subject: CurrentValueSubject<T, Never>
    
    init(initialValue: T) {
        self._value = initialValue
        self.subject = CurrentValueSubject(initialValue)
    }
    
    public private(set) var value: T {
        get {
            lock.withLock {
                _value
            }
        }
        set {
            lock.withLock {
                _value = newValue
                subject.send(newValue)
            }
        }
    }
    
    public var publisher: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public subscript<Value>(keyPath: KeyPath<T, Value>) -> Value {
        value[keyPath: keyPath]
    }
    
    public func update(_ newValue: T) {
        mutate { $0 = newValue }
    }
    
//    public func updateValue<Value>(_ newValue: Value, for keyPath: WritableKeyPath<T, Value>) {
//        mutate { $0[keyPath: keyPath] = newValue }
//    }
    
    /// Performs an atomic read-modify-write operation
    /// Use this for compound operations like +=, -=, etc. to ensure atomicity
    private func mutate(_ transform: @Sendable (inout T) -> Void) {
        lock.withLock {
            transform(&_value)
            subject.send(_value)
        }
    }
}
