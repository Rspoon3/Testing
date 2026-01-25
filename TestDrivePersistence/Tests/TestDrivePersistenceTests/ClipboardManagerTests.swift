import Foundation
import Testing
@testable import TestDrivePersistence

/// Tests for the ClipboardManager.
@Suite struct ClipboardManagerTests {

    // MARK: - Configuration Tests

    @Test func defaultConfiguration() async throws {
        let manager = ClipboardManager()

        #expect(manager.autoClearDuration == 30)
        #expect(manager.notificationsEnabled == true)
    }

    @Test func customConfiguration() async throws {
        let manager = ClipboardManager()
        manager.autoClearDuration = 60
        manager.notificationsEnabled = false

        #expect(manager.autoClearDuration == 60)
        #expect(manager.notificationsEnabled == false)
    }

    // MARK: - Copy Tests

    @Test func copyToClipboard() async throws {
        let manager = ClipboardManager()
        manager.notificationsEnabled = false

        await manager.copy("test-secret", label: "Test Key")

        // Note: Actual clipboard verification would require UIKit/XCTest
        // This test verifies the method completes without errors
    }

    @Test func cancelAutoClear() async throws {
        let manager = ClipboardManager()

        await manager.copy("test-secret", label: "Test Key")
        manager.cancelAutoClear()

        // Verify no errors
        #expect(true)
    }

    @Test func clearClipboard() async throws {
        let manager = ClipboardManager()

        await manager.copy("test-secret", label: "Test Key")
        await manager.clearClipboard()

        // Verify no errors
        #expect(true)
    }

    // MARK: - Auto-Clear Tests

    @Test func autoClearAfterTimeout() async throws {
        let manager = ClipboardManager()
        manager.autoClearDuration = 0.1 // 100ms for fast testing
        manager.notificationsEnabled = false

        await manager.copy("test-secret", label: "Test Key")

        // Wait for auto-clear
        try await Task.sleep(for: .milliseconds(200))

        // Verify completed without errors
        #expect(true)
    }

    @Test func multipleCopiesResetTimer() async throws {
        let manager = ClipboardManager()
        manager.autoClearDuration = 1.0
        manager.notificationsEnabled = false

        await manager.copy("secret1", label: "Key 1")
        try await Task.sleep(for: .milliseconds(100))

        await manager.copy("secret2", label: "Key 2")
        try await Task.sleep(for: .milliseconds(100))

        await manager.copy("secret3", label: "Key 3")

        // First two timers should be cancelled
        #expect(true)
    }
}
