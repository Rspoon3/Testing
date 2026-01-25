import Testing
@testable import TestDriveCore

@Suite("TestDriveCore Tests")
struct TestDriveCoreTests {

    @Test("TestDriveCore exists")
    func testDriveCoreExists() {
        // Simple test to verify the module is accessible
        let _ = TestDriveCore.self
    }
}
