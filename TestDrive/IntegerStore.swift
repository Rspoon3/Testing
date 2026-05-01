import Foundation
import Combine
import os.lock

public class IntegerStore {
    private var _value: OSAllocatedUnfairLock<Int>
    private let subject: CurrentValueSubject<Int, Never>
    
    public init(initialValue: Int = 0) {
        self._value = OSAllocatedUnfairLock(initialState: initialValue)
        self.subject = CurrentValueSubject(initialValue)
    }
    
    /// Retrieves the locally stored user, if available.
    public var value: Int {
        _value.withLock { $0 }
    }
    
    public var publisher: AnyPublisher<Int, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public func increment() {
        modify { $0 += 1 }
    }
    
    public func decrement() {
        modify { $0 -= 1 }
    }
    
    public func modify(_ transform: @Sendable (inout Int) -> Void) {
        _ = _value.withLock { value in
            transform(&value)
            subject.send(value)
            return value
        }
    }
}

public actor Test {
    @Published private(set) var value = 0
    
    func increment() {
        value += 1
    }
}
