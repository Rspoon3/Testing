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

public enum CaseDetectionMacro: MemberMacro {
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
                message: CaseDetectionDiagnostic.notAnEnum
            )
            context.diagnose(diagnostic)
            return []
        }

        return declaration.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
            .map { $0.elements.first!.name }
            .map { ($0, $0.initialUppercased) }
            .map { original, uppercased in
                """
                var is\(raw: uppercased): Bool {
                    if case .\(raw: original) = self {
                        return true
                    }

                    return false
                }
                """
            }
    }
}

/// Diagnostic messages for CaseDetection macro
enum CaseDetectionDiagnostic: String, DiagnosticMessage {
    case notAnEnum

    var severity: DiagnosticSeverity {
        .error
    }

    var message: String {
        switch self {
        case .notAnEnum:
            "@CaseDetection can only be applied to enums"
        }
    }

    var diagnosticID: MessageID {
        MessageID(domain: "CaseDetectionMacro", id: rawValue)
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
