//
//  PhoneNumberCleanerTests.swift
//  TestingTests
//
//  Created by Ricky on 10/28/24.
//

import XCTest
@testable import Testing

final class PhoneNumberCleanerTests: XCTestCase {
    private let sut = PhoneNumberCleaner()
    
    func test_cleanForRealtimeFormatting() {
        XCTAssertEqual("1", sut.cleanForRealtimeFormatting(using: "1"))
        XCTAssertEqual("12", sut.cleanForRealtimeFormatting(using: "12"))
        XCTAssertEqual("(123)", sut.cleanForRealtimeFormatting(using: "123"))
        XCTAssertEqual("(123)", sut.cleanForRealtimeFormatting(using: "123)"))
        XCTAssertEqual("(123)", sut.cleanForRealtimeFormatting(using: "123) "))
        XCTAssertEqual("(123)", sut.cleanForRealtimeFormatting(using: "(123 "))
        XCTAssertEqual("12", sut.cleanForRealtimeFormatting(using: "(12 "))
        XCTAssertEqual("(123)", sut.cleanForRealtimeFormatting(using: "(123)"))
        XCTAssertEqual("(123)", sut.cleanForRealtimeFormatting(using: "(123) "))
        XCTAssertEqual("(123) 4", sut.cleanForRealtimeFormatting(using: "(123) 4"))
        XCTAssertEqual("(123) 45", sut.cleanForRealtimeFormatting(using: "(123) 45"))
        XCTAssertEqual("(123) 456", sut.cleanForRealtimeFormatting(using: "(123) 456"))
        XCTAssertEqual("(123) 456", sut.cleanForRealtimeFormatting(using: "(123) 456-"))
        XCTAssertEqual("(123) 456-7", sut.cleanForRealtimeFormatting(using: "(123) 456-7"))
        XCTAssertEqual("(123) 456-78", sut.cleanForRealtimeFormatting(using: "(123) 456-78"))
        XCTAssertEqual("(123) 456-789", sut.cleanForRealtimeFormatting(using: "(123) 456-789"))
        XCTAssertEqual("(123) 456-7890", sut.cleanForRealtimeFormatting(using: "(123) 456-7890"))
        XCTAssertEqual("(234) 567-8901", sut.cleanForRealtimeFormatting(using: "(123) 456-78901"))
    }
}
