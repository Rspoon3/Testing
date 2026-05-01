//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Richard Witherspoon on 8/9/20.
//

import Testing
@testable import TestDrive

struct TestDriveTests {

    @Test func testIncreaseValue() async throws {
        let object = AsyncObject()
        let currentValue = object.count
        object.incrementCountDetached()
        
        await Task.megaYield()

        #expect(object.count == currentValue + 1)
    }
}

final class AsyncObject: @unchecked Sendable {
    private(set) var count = 1
    
    func incrementCountDetached() {
        Task {
            count += 1
        }
    }
}

extension Task where Success == Never, Failure == Never {
  /// Suspends the current task a number of times, giving the system time to
  /// perform other concurrent work.
  ///
  /// This is a blunt tool that can make flakey async tests a little less flakey
  /// by improving the odds that other async work has enough time to start.
  public static func megaYield(count: Int = 500) async {
    for _ in 1...count {
      await Task.yield()
    }
  }
}
