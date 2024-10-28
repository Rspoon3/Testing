//
//  PhoneNumberFormatStyleTests.swift
//  TestingTests
//
//  Created by Ricky on 10/28/24.
//

import XCTest
@testable import Testing

final class PhoneNumberFormatStyleTests: XCTestCase {
    
    func testFullFormatting(){
        XCTAssertEqual("1", "1".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("12", "12".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123)", "123".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123) 4", "1234".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123) 45", "12345".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123) 456", "123456".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123) 456-7", "1234567".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123) 456-78", "12345678".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123) 456-789", "123456789".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123) 456-7890", "1234567890".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123) 456-7890", "12345678901".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123) 456-7890", "123456789012".formatted(PhoneNumberFormatStyle(.full)))
        XCTAssertEqual("(123) 456-7890", "1234567890123".formatted(PhoneNumberFormatStyle(.full)))
    }
    
    func testAreaCodeFormatting(){
        XCTAssertEqual("1", "1".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("12", "12".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "123".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "1234".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "12345".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "123456".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "1234567".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "12345678".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "123456789".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "1234567890".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "12345678901".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "123456789012".formatted(PhoneNumberFormatStyle(.areaCode)))
        XCTAssertEqual("123", "1234567890123".formatted(PhoneNumberFormatStyle(.areaCode)))
    }
    
    func testExcludingAreaCodeFormatting(){
        XCTAssertNil("1".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertNil("12".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertNil("123".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertEqual("4", "1234".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertEqual("45", "12345".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertEqual("456", "123456".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertEqual("456-7", "1234567".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertEqual("456-78", "12345678".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertEqual("456-789", "123456789".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertEqual("456-7890", "1234567890".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertEqual("456-7890", "12345678901".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertEqual("456-7890", "123456789012".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
        XCTAssertEqual("456-7890", "1234567890123".formatted(PhoneNumberFormatStyle(.excludingAreaCode)))
    }
}
