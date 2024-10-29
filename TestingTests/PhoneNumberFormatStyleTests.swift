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
        XCTAssertEqual("1", "1".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("12", "12".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123)", "123".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123) 4", "1234".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123) 45", "12345".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123) 456", "123456".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123) 456-7", "1234567".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123) 456-78", "12345678".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123) 456-789", "123456789".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123) 456-7890", "1234567890".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123) 456-7890", "12345678901".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123) 456-7890", "123456789012".formatted(.phoneNumber(.full)) ?? "")
        XCTAssertEqual("(123) 456-7890", "1234567890123".formatted(.phoneNumber(.full)) ?? "")
    }
    
    func testAreaCodeFormatting(){
        XCTAssertEqual("1", "1".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("12", "12".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "123".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "1234".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "12345".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "123456".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "1234567".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "12345678".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "123456789".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "1234567890".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "12345678901".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "123456789012".formatted(.phoneNumber(.areaCode)) ?? "")
        XCTAssertEqual("123", "1234567890123".formatted(.phoneNumber(.areaCode)) ?? "")
    }
    
    func testExcludingAreaCodeFormatting(){
        XCTAssertNil("1".formatted(.phoneNumber(.excludingAreaCode)))
        XCTAssertNil("12".formatted(.phoneNumber(.excludingAreaCode)))
        XCTAssertNil("123".formatted(.phoneNumber(.excludingAreaCode)))
        XCTAssertEqual("4", "1234".formatted(.phoneNumber(.excludingAreaCode)) ?? "")
        XCTAssertEqual("45", "12345".formatted(.phoneNumber(.excludingAreaCode)) ?? "")
        XCTAssertEqual("456", "123456".formatted(.phoneNumber(.excludingAreaCode)) ?? "")
        XCTAssertEqual("456-7", "1234567".formatted(.phoneNumber(.excludingAreaCode)) ?? "")
        XCTAssertEqual("456-78", "12345678".formatted(.phoneNumber(.excludingAreaCode)) ?? "")
        XCTAssertEqual("456-789", "123456789".formatted(.phoneNumber(.excludingAreaCode)) ?? "")
        XCTAssertEqual("456-7890", "1234567890".formatted(.phoneNumber(.excludingAreaCode)) ?? "")
        XCTAssertEqual("456-7890", "12345678901".formatted(.phoneNumber(.excludingAreaCode)) ?? "")
        XCTAssertEqual("456-7890", "123456789012".formatted(.phoneNumber(.excludingAreaCode)) ?? "")
        XCTAssertEqual("456-7890", "1234567890123".formatted(.phoneNumber(.excludingAreaCode)) ?? "")
    }
}
