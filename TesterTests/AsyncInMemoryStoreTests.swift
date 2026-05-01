//
//  AsyncInMemoryStoreTests.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/20/25.
//

import Foundation
import Testing
@testable import Tester

struct AsyncInMemoryStoreTests {

    // MARK: - Basic Functionality Tests

    @Test("Basic value access operations")
    func basicValueAccess() async {
        let store = AsyncInMemoryStore<Int>(initialValue: 42)
        #expect(await store.value == 42)

        await store.value = 100
        #expect(await store.value == 100)
    }

    @Test("Basic mutate operations")
    func mutateBasicOperation() async {
        let store = AsyncInMemoryStore<Int>(initialValue: 10)

        await store.mutate { $0 += 5 }
        #expect(await store.value == 15)

        await store.mutate { $0 *= 2 }
        #expect(await store.value == 30)
    }

    // MARK: - Thread Safety Tests

    @Test("Concurrent writes with mutate are thread-safe")
    func concurrentWritesWithMutateAreThreadSafe() async {
        let store = AsyncInMemoryStore<Int>(initialValue: 0)
        let iterations = 10_000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    await store.mutate { $0 += 1 }
                }
            }
        }

        #expect(await store.value == iterations)
    }

    @Test("Concurrent reads and writes with mutate are thread-safe")
    func concurrentReadsAndWritesWithMutateAreThreadSafe() async {
        let store = AsyncInMemoryStore<Int>(initialValue: 0)
        let writeIterations = 5_000
        let readIterations = 5_000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<writeIterations {
                group.addTask {
                    await store.mutate { $0 += 1 }
                }
            }

            for _ in 0..<readIterations {
                group.addTask {
                    _ = await store.value
                }
            }
        }

        #expect(await store.value == writeIterations)
    }

    // MARK: - Complex Mutate Operations

    @Test("Complex mutate operations work correctly")
    func complexMutateOperations() async {
        let store = AsyncInMemoryStore<String>(initialValue: "Hello")

        await store.mutate { value in
            value += " World"
            value = value.uppercased()
        }

        #expect(await store.value == "HELLO WORLD")
    }

    @Test("Mutate works with custom structs")
    func mutateWithStructs() async {
        struct Counter {
            var count: Int
            var name: String
        }

        let store = AsyncInMemoryStore<Counter>(initialValue: Counter(count: 0, name: "Test"))

        await store.mutate { counter in
            counter.count += 10
            counter.name = "Updated"
        }

        let final = await store.value
        #expect(final.count == 10)
        #expect(final.name == "Updated")
    }

    // MARK: - Publisher Tests

    @Test("Publisher emits changes for both direct assignment and mutate")
    func publisherEmitsChanges() async {
        let store = AsyncInMemoryStore<Int>(initialValue: 0)
        var receivedValues: [Int] = []

        let cancellable = store.publisher
            .sink { value in
                receivedValues.append(value)
            }

        try? await Task.sleep(nanoseconds: 10_000_000) // wait for sink to attach

        await store.value = 1
        await store.mutate { $0 = 2 }

        // wait for Combine to catch up
        try? await Task.sleep(nanoseconds: 20_000_000)

        cancellable.cancel()
        #expect(receivedValues == [0, 1, 2])
    }
}
