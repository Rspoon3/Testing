//
//  ListItem.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 12/8/23.
//

import Foundation
import LoremSwiftum

struct ListItem: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let offers: [Offer]
    
    static func exampleData() -> [ListItem] {
        let array = (0..<5)
        
        return array.map { _ in
            ListItem(
                title: Lorem.words(Int.random(in: 1..<3)),
                offers: Bool.random() ? [] : [Offer.example, .example, .example, .example , .example, .example, .example, .example]
            )
        }
    }
}
