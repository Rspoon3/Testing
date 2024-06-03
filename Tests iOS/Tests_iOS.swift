//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Richard Witherspoon on 8/9/20.
//

import XCTest
@testable import Testing

final class ContentViewModelTests: XCTestCase {
    
    func testIncreaseValue() async throws {
        var count = 1
        count += 1
        XCTAssertEqual(count, 2)
    }
}
