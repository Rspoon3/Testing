//
//  PhoneNumberUtilityTests.swift
//  TestingTests
//
//  Created by Ricky on 10/28/24.
//

import XCTest
@testable import Testing

final class PhoneNumberTests: XCTestCase {
    private let utility = PhoneNumberUtility()

    func testPassingInitializer() throws {
        _ = try PhoneNumber(areaCode: "123", exchange: "456", number: "7890")
        _ = try PhoneNumber(areaCode: 123, exchange: 456, number: 7890)
        _ = try PhoneNumber("1234567890")
        _ = try PhoneNumber(1234567890)
    }
    
    func testAreaCodeError() {
        do {
            _ = try PhoneNumber(areaCode: "1123", exchange: "456", number: "7890")
            XCTFail("Expected Area Code Error")
        } catch {
            XCTAssertEqual(error as? PhoneNumberError, PhoneNumberError.invalidAreaCode)
        }
    }
    
    func testExchangeCodeError() {
        do {
            _ = try PhoneNumber(areaCode: "123", exchange: "1456", number: "7890")
            XCTFail("Expected Area Code Error")
        } catch {
            XCTAssertEqual(error as? PhoneNumberError, PhoneNumberError.invalidExchange)
        }
    }
    
    func testNumberError() {
        do {
            _ = try PhoneNumber(areaCode: "123", exchange: "456", number: "17890")
            XCTFail("Expected Area Code Error")
        } catch {
            XCTAssertEqual(error as? PhoneNumberError, PhoneNumberError.invalidNumber)
        }
    }
    
    func testRegexReplacement() {
        XCTAssertThrowsError(_ = try PhoneNumber(areaCode: "A23", exchange: "456", number: "7890"))
        XCTAssertThrowsError(_ = try PhoneNumber(areaCode: "123", exchange: "A456", number: "7890"))
        XCTAssertThrowsError(_ = try PhoneNumber(areaCode: "123", exchange: "456", number: "A7890"))
    }
    
    func testFormatting() throws {
        let phoneNumber = try PhoneNumber(areaCode: "123", exchange: "456", number: "7890")
        XCTAssertEqual(phoneNumber.formatted(.areaCode), "123")
        XCTAssertEqual(phoneNumber.formatted(.excludingAreaCode), "456-7890")
        XCTAssertEqual(phoneNumber.formatted(.full), "(123) 456-7890")
    }
}
