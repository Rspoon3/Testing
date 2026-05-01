//
//  CSRFTokenExtractor.swift
//  Testing
//
//  Created by Ricky on 3/22/25.
//

import Foundation

struct CSRFTokenExtractor {
    
    // MARK: - Public
    
    func extract(from html: String) -> String? {
        extractFromMetaTag(html: html) ?? extractFromJavaScript(html: html)
    }
    
    // MARK: - Private
    
    private func extractFromMetaTag(html: String) -> String? {
        guard let range = html.range(of: #"<meta name="csrf-token" content="([^"]+)""#, options: .regularExpression) else {
            return nil
        }
        
        let metaTag = html[range]
        
        guard let tokenRange = metaTag.range(of: #"content="([^"]+)""#, options: .regularExpression) else {
            return nil
        }
        
        let tokenPart = metaTag[tokenRange]
        
        guard let actualTokenRange = tokenPart.range(of: #""([^"]+)""#, options: .regularExpression) else {
            return nil
        }
        
        let token = String(tokenPart[actualTokenRange]).replacingOccurrences(of: "\"", with: "")
        return token
    }
    
    private func extractFromJavaScript(html: String) -> String? {
        let pattern = #"_token\s*=\s*['"]([^'"]+)['"]"#
        
        guard let range = html.range(of: pattern, options: .regularExpression) else {
            return nil
        }
        
        let match = html[range]
        
        guard let valueRange = match.range(of: #"['"]([^'"]+)['"]"#, options: .regularExpression) else {
            return nil
        }
        
        let valueMatch = match[valueRange]
        
        let token = String(valueMatch).replacingOccurrences(of: #"['"](.*)['"]{1}"#, with: "$1", options: .regularExpression)
        return token
    }
}
