//
//  AsyncInMemoryStore.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/20/25.
//

import Foundation
import Combine

actor AsyncInMemoryStore<T> {
    private var _value: T
    nonisolated private let subject: CurrentValueSubject<T, Never>
    
    init(initialValue: T) {
        self._value = initialValue
        self.subject = CurrentValueSubject(initialValue)
    }

    // MARK: - Computed Property Access
    var value: T {
        get { _value }
        set {
            _value = newValue
            subject.send(newValue)
        }
    }

    // MARK: - Publisher
    nonisolated var publisher: AnyPublisher<T, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: - KeyPath Access
    func get<Value>(_ keyPath: KeyPath<T, Value>) -> Value {
        _value[keyPath: keyPath]
    }

    func set<Value>(_ keyPath: WritableKeyPath<T, Value>, to newValue: Value) {
        var copy = _value
        copy[keyPath: keyPath] = newValue
        _value = copy
        subject.send(copy)
    }

    // MARK: - Mutate
    func mutate(_ transform: (inout T) -> Void) {
        transform(&_value)
        subject.send(_value)
    }
}
