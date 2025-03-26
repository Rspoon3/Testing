//
//  Locale+RawRepresentable.swift
//  Testing
//
//  Created by Ricky on 3/26/25.
//

import Foundation

extension Locale: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        guard
            let data = rawValue.data(using: .utf8),
            let identifier = try? JSONDecoder().decode(String.self, from: data)
        else {
            return nil
        }
        
        self = .init(identifier: identifier)
    }
    
    public var rawValue: String {
        guard
            let data = try? JSONEncoder().encode(self.identifier),
            let result = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        
        return result
    }
}
