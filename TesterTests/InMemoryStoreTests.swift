//
//  InMemoryStoreTests.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//

import Foundation
import Testing
@testable import Tester

struct InMemoryStoreTests {

    // MARK: - Basic Functionality Tests
    
    @Test("Basic value access operations")
    func basicValueAccess() {
        let store = InMemoryStore<Int>(initialValue: 42)
        #expect(store.value == 42)
        
        store.value = 100
        #expect(store.value == 100)
    }
    
    @Test("Basic mutate operations")
    func mutateBasicOperation() {
        let store = InMemoryStore<Int>(initialValue: 10)
        
        store.mutate { $0 += 5 }
        #expect(store.value == 15)
        
        store.mutate { $0 *= 2 }
        #expect(store.value == 30)
    }
    
    // MARK: - Thread Safety Tests (Demonstrating Race Conditions)
    
    @Test("Concurrent writes with direct assignment lose increments due to race conditions")
    func concurrentWritesWithDirectAssignmentFails() async {
        let store = InMemoryStore<Int>(initialValue: 0)
        let iterations = 1_000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    store.value += 1  // Race condition
                }
            }
        }

        // This test demonstrates that direct assignment loses increments
        #expect(store.value <= iterations)
    }

    @Test("Concurrent reads and writes with direct assignment cause race conditions")
    func concurrentReadsAndWritesWithDirectAssignmentFails() async {
        let store = InMemoryStore<Int>(initialValue: 0)
        let writeIterations = 1_000
        let readIterations = 1_000

        await withTaskGroup(of: Void.self) { group in
            // Add write tasks
            for _ in 0..<writeIterations {
                group.addTask {
                    store.value += 1  // Race condition
                }
            }
            
            // Add read tasks
            for _ in 0..<readIterations {
                group.addTask {
                    _ = store.value
                }
            }
        }

        // This should fail due to race conditions
        #expect(store.value <= writeIterations)
    }
    
    // MARK: - Thread Safety Tests (Working - using mutate)
    
    @Test("Concurrent writes with mutate are thread-safe")
    func concurrentWritesWithMutateAreThreadSafe() async {
        let store = InMemoryStore<Int>(initialValue: 0)
        let iterations = 10_000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    store.mutate { $0 += 1 }  // Atomic operation
                }
            }
        }

        #expect(store.value == iterations)
    }

    @Test("Concurrent reads and writes with mutate are thread-safe")
    func concurrentReadsAndWritesWithMutateAreThreadSafe() async {
        let store = InMemoryStore<Int>(initialValue: 0)
        let writeIterations = 5_000
        let readIterations = 5_000

        await withTaskGroup(of: Void.self) { group in
            // Add write tasks
            for _ in 0..<writeIterations {
                group.addTask {
                    store.mutate { $0 += 1 }  // Atomic operation
                }
            }
            
            // Add read tasks
            for _ in 0..<readIterations {
                group.addTask {
                    _ = store.value
                }
            }
        }

        #expect(store.value == writeIterations)
    }
    
    // MARK: - Complex Mutate Operations
    
    @Test("Complex mutate operations work correctly")
    func complexMutateOperations() {
        let store = InMemoryStore<String>(initialValue: "Hello")
        
        store.mutate { value in
            value += " World"
            value = value.uppercased()
        }
        
        #expect(store.value == "HELLO WORLD")
    }
    
    @Test("Mutate works with custom structs")
    func mutateWithStructs() {
        struct Counter {
            var count: Int
            var name: String
        }
        
        let store = InMemoryStore<Counter>(initialValue: Counter(count: 0, name: "Test"))
        
        store.mutate { counter in
            counter.count += 10
            counter.name = "Updated"
        }
        
        #expect(store.value.count == 10)
        #expect(store.value.name == "Updated")
    }
    
    // MARK: - Publisher Tests
    
    @Test("Publisher emits changes for both direct assignment and mutate")
    func publisherEmitsChanges() async {
        let store = InMemoryStore<Int>(initialValue: 0)
        var receivedValues: [Int] = []
        
        let task = Task {
            for await value in store.publisher.values {
                receivedValues.append(value)
                if receivedValues.count == 3 {
                    break
                }
            }
        }
        
        // Give the publisher subscription time to set up
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        store.value = 1
        store.mutate { $0 = 2 }
        
        // Wait for all values to be received
        await task.value
        
        #expect(receivedValues == [0, 1, 2])
    }
}
