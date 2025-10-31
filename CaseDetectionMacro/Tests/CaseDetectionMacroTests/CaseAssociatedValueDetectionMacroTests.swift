//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@testable import CaseDetectionPlugin

@Suite("CaseAssociatedValueDetection Macro Tests")
struct CaseAssociatedValueDetectionMacroTests {
    private let macros = ["CaseAssociatedValueDetection": CaseAssociatedValueDetectionMacro.self]

    @Test("Single associated value")
    func testSingleAssociatedValue() {
        assertMacroExpansion(
            """
            @CaseAssociatedValueDetection
            enum Result {
              case success(value: Int)
              case failure(error: String)
            }
            """,
            expandedSource: """
              enum Result {
                case success(value: Int)
                case failure(error: String)

                struct SuccessAssociatedValues {
                    let value: Int
                }

                var success: SuccessAssociatedValues? {
                    if case .success(let value) = self {
                        return SuccessAssociatedValues(value: value)
                    }
                    return nil
                }

                struct FailureAssociatedValues {
                    let error: String
                }

                var failure: FailureAssociatedValues? {
                    if case .failure(let error) = self {
                        return FailureAssociatedValues(error: error)
                    }
                    return nil
                }
              }
              """,
            macros: macros,
            indentationWidth: .spaces(2)
        )
    }

    @Test("Multiple associated values")
    func testMultipleAssociatedValues() {
        assertMacroExpansion(
            """
            @CaseAssociatedValueDetection
            enum MyState {
              case sent(date: Date, count: Int)
            }
            """,
            expandedSource: """
              enum MyState {
                case sent(date: Date, count: Int)

                struct SentAssociatedValues {
                    let date: Date
                    let count: Int
                }

                var sent: SentAssociatedValues? {
                    if case .sent(let date, let count) = self {
                        return SentAssociatedValues(date: date, count: count)
                    }
                    return nil
                }
              }
              """,
            macros: macros,
            indentationWidth: .spaces(2)
        )
    }

    @Test("Mixed cases with and without associated values")
    func testMixedCases() {
        assertMacroExpansion(
            """
            @CaseAssociatedValueDetection
            enum MyState {
              case connecting
              case error(localizedDescription: String)
              case sent
            }
            """,
            expandedSource: """
              enum MyState {
                case connecting
                case error(localizedDescription: String)
                case sent

                struct ErrorAssociatedValues {
                    let localizedDescription: String
                }

                var error: ErrorAssociatedValues? {
                    if case .error(let localizedDescription) = self {
                        return ErrorAssociatedValues(localizedDescription: localizedDescription)
                    }
                    return nil
                }
              }
              """,
            macros: macros,
            indentationWidth: .spaces(2)
        )
    }

    @Test("Enum as associated value (recursive)")
    func testEnumAsAssociatedValue() {
        assertMacroExpansion(
            """
            @CaseAssociatedValueDetection
            enum MyState {
              case connecting
              case status(UTSStatus)
            }
            """,
            expandedSource: """
              enum MyState {
                case connecting
                case status(UTSStatus)

                struct StatusAssociatedValues {
                    let UTSStatus: UTSStatus
                }

                var status: StatusAssociatedValues? {
                    if case .status(let UTSStatus) = self {
                        return StatusAssociatedValues(UTSStatus: UTSStatus)
                    }
                    return nil
                }
              }
              """,
            macros: macros,
            indentationWidth: .spaces(2)
        )
    }

    @Test("Complex types (optionals and generics)")
    func testComplexTypes() {
        assertMacroExpansion(
            """
            @CaseAssociatedValueDetection
            enum Response {
              case data(result: Result<Data, Error>, metadata: [String: Any]?)
            }
            """,
            expandedSource: """
              enum Response {
                case data(result: Result<Data, Error>, metadata: [String: Any]?)

                struct DataAssociatedValues {
                    let result: Result<Data, Error>
                    let metadata: [String: Any]?
                }

                var data: DataAssociatedValues? {
                    if case .data(let result, let metadata) = self {
                        return DataAssociatedValues(result: result, metadata: metadata)
                    }
                    return nil
                }
              }
              """,
            macros: macros,
            indentationWidth: .spaces(2)
        )
    }

    @Test("Case with tuple type")
    func testTupleType() {
        assertMacroExpansion(
            """
            @CaseAssociatedValueDetection
            enum Event {
              case location(coordinates: (Double, Double))
            }
            """,
            expandedSource: """
              enum Event {
                case location(coordinates: (Double, Double))

                struct LocationAssociatedValues {
                    let coordinates: (Double, Double)
                }

                var location: LocationAssociatedValues? {
                    if case .location(let coordinates) = self {
                        return LocationAssociatedValues(coordinates: coordinates)
                    }
                    return nil
                }
              }
              """,
            macros: macros,
            indentationWidth: .spaces(2)
        )
    }

    @Test("Custom struct as associated value")
    func testCustomStructAsAssociatedValue() {
        assertMacroExpansion(
            """
            @CaseAssociatedValueDetection
            enum AuthState {
              case loggedIn(user: UserInfo)
              case loggedOut
            }
            """,
            expandedSource: """
              enum AuthState {
                case loggedIn(user: UserInfo)
                case loggedOut

                struct LoggedInAssociatedValues {
                    let user: UserInfo
                }

                var loggedIn: LoggedInAssociatedValues? {
                    if case .loggedIn(let user) = self {
                        return LoggedInAssociatedValues(user: user)
                    }
                    return nil
                }
              }
              """,
            macros: macros,
            indentationWidth: .spaces(2)
        )
    }

    @Test("Fails on struct")
    func testFailsOnStruct() {
        assertMacroExpansion(
            """
            @CaseAssociatedValueDetection
            struct Animal {
              let name: String
            }
            """,
            expandedSource: """
              struct Animal {
                let name: String
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@CaseAssociatedValueDetection can only be applied to enums",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(2)
        )
    }

    @Test("Fails on class")
    func testFailsOnClass() {
        assertMacroExpansion(
            """
            @CaseAssociatedValueDetection
            class Animal {
              let name: String
            }
            """,
            expandedSource: """
              class Animal {
                let name: String
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@CaseAssociatedValueDetection can only be applied to enums",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(2)
        )
    }

    @Test("Fails on actor")
    func testFailsOnActor() {
        assertMacroExpansion(
            """
            @CaseAssociatedValueDetection
            actor Animal {
              let name: String
            }
            """,
            expandedSource: """
              actor Animal {
                let name: String
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@CaseAssociatedValueDetection can only be applied to enums",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ],
            macros: macros,
            indentationWidth: .spaces(2)
        )
    }
}
