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

@Suite("CaseDetection Macro Tests")
struct CaseDetectionMacroTests {
    private let macros = ["CaseDetection": CaseDetectionMacro.self]

    @Test("Expansion adds computed properties")
    func testExpansionAddsComputedProperties() {
        assertMacroExpansion(
            """
            @CaseDetection
            enum Animal {
              case dog
              case cat(curious: Bool)
            }
            """,
            expandedSource: """
              enum Animal {
                case dog
                case cat(curious: Bool)

                var isDog: Bool {
                  if case .dog = self {
                    return true
                  }

                  return false
                }

                var isCat: Bool {
                  if case .cat = self {
                    return true
                  }

                  return false
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
            @CaseDetection
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
                    message: "@CaseDetection can only be applied to enums",
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
            @CaseDetection
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
                    message: "@CaseDetection can only be applied to enums",
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
            @CaseDetection
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
                    message: "@CaseDetection can only be applied to enums",
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
