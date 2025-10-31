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

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

/// Generates namespaced accessors for enum cases with associated values.
///
/// For each case with associated values, generates:
/// - A nested struct containing the associated values
/// - A computed property returning an optional struct
public enum CaseAssociatedValueDetectionMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure the macro is only applied to enums
        guard declaration.is(EnumDeclSyntax.self) else {
            let diagnostic = Diagnostic(
                node: node,
                message: CaseAssociatedValueDetectionDiagnostic.notAnEnum
            )
            context.diagnose(diagnostic)
            return []
        }

        // Extract all enum cases with associated values
        let casesWithValues = declaration.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .flatMap { $0.elements }
            .filter { $0.parameterClause != nil }

        var declarations: [DeclSyntax] = []

        for caseElement in casesWithValues {
            let caseName = caseElement.name
            let caseNameText = caseName.text
            let structName = "\(caseName.initialUppercased)AssociatedValues"

            guard let parameters = caseElement.parameterClause?.parameters else {
                continue
            }

            // Generate struct declaration with associated value properties
            let structProperties = parameters.map { param in
                let paramName: String
                if let firstName = param.firstName {
                    paramName = firstName.text
                } else if let secondName = param.secondName {
                    paramName = secondName.text
                } else {
                    paramName = "_"
                }
                let paramType = param.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
                return "let \(paramName): \(paramType)"
            }.joined(separator: "\n    ")

            let structDecl: DeclSyntax = """
                struct \(raw: structName) {
                    \(raw: structProperties)
                }
                """

            // Generate computed property with pattern matching
            let letBindings = parameters.map { param -> String in
                let paramName: String
                if let firstName = param.firstName {
                    paramName = firstName.text
                } else if let secondName = param.secondName {
                    paramName = secondName.text
                } else {
                    paramName = "_"
                }
                return "let \(paramName)"
            }.joined(separator: ", ")

            let initArgs = parameters.map { param -> String in
                let paramName: String
                if let firstName = param.firstName {
                    paramName = firstName.text
                } else if let secondName = param.secondName {
                    paramName = secondName.text
                } else {
                    paramName = "_"
                }
                return "\(paramName): \(paramName)"
            }.joined(separator: ", ")

            let propertyDecl: DeclSyntax = """
                var \(raw: caseNameText): \(raw: structName)? {
                    if case .\(raw: caseNameText)(\(raw: letBindings)) = self {
                        return \(raw: structName)(\(raw: initArgs))
                    }
                    return nil
                }
                """

            declarations.append(structDecl)
            declarations.append(propertyDecl)
        }

        return declarations
    }
}

/// Diagnostic messages for CaseAssociatedValueDetection macro
enum CaseAssociatedValueDetectionDiagnostic: String, DiagnosticMessage {
    case notAnEnum

    var severity: DiagnosticSeverity {
        .error
    }

    var message: String {
        switch self {
        case .notAnEnum:
            "@CaseAssociatedValueDetection can only be applied to enums"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "CaseAssociatedValueDetectionMacro", id: rawValue)
    }
}

extension TokenSyntax {
    fileprivate var initialUppercased: String {
        let name = self.text
        guard let initial = name.first else {
            return name
        }

        return "\(initial.uppercased())\(name.dropFirst())"
    }
}
