//
//  Item.swift
//  Testing
//
//  Created by Richard Witherspoon on 5/25/23.
//

import Foundation

struct Item: Identifiable {
    let id = UUID()
    let title: String
    let isFavorite: Bool
    let favoriteRank: Int?
    let isRecommended: Bool
    let popularityRank: Int
    
    static let previewData: [Item] = [
        Item(title: "Aye my name is Ricky", isFavorite: true, favoriteRank: 14, isRecommended: false, popularityRank: 10),
        Item(title: "Aye my name is ricky", isFavorite: true, favoriteRank: 5, isRecommended: false, popularityRank: 20),
        Item(title: "4 This is a tile", isFavorite: true, favoriteRank: 34, isRecommended: true, popularityRank: 30),
        Item(title: "58 This is a tile", isFavorite: true, favoriteRank: 5, isRecommended: true, popularityRank: 5),
        Item(title: " 904 This is a tile", isFavorite: true, favoriteRank: 214, isRecommended: true, popularityRank: 3),
        Item(title: "This is a tile", isFavorite: true, favoriteRank: 554, isRecommended: true, popularityRank: 3),
        Item(title: "This is a tile", isFavorite: true, favoriteRank: 234, isRecommended: true, popularityRank: 3),
        Item(title: "AThis is a tile", isFavorite: true, favoriteRank: 1, isRecommended: false, popularityRank: 5),
        Item(title: "ABThis is a tile", isFavorite: true, favoriteRank: 0, isRecommended: false, popularityRank: 5),
        Item(title: "This is a tile", isFavorite: false, favoriteRank: nil, isRecommended: false, popularityRank: 1),
        Item(title: "BAD This is a tile", isFavorite: false, favoriteRank: nil, isRecommended: true, popularityRank: 33),
        Item(title: "This is a tile", isFavorite: false, favoriteRank: nil, isRecommended: true, popularityRank: 33),
        Item(title: "AB This is a tile", isFavorite: false, favoriteRank: nil, isRecommended: false, popularityRank: 10),
        Item(title: "This is a tile", isFavorite: false, favoriteRank: nil, isRecommended: true, popularityRank: 45),
        Item(title: "DANMG This is a tile", isFavorite: false, favoriteRank: nil, isRecommended: false, popularityRank: 90),
        Item(title: "This is a tile", isFavorite: false, favoriteRank: nil, isRecommended: false, popularityRank: 10),
        Item(title: "This is a tile", isFavorite: false, favoriteRank: nil, isRecommended: true, popularityRank: 40),
    ]
}


extension Array where Element == Item {
    func sortedByKeyPath() -> Self {
        sorted(using: [
            KeyPathComparator(\.title, comparator: .normalized, order: .forward),
            KeyPathComparator(\.favoriteRank, order: .forward, nilOrder: .reverse),
            KeyPathComparator(\.isRecommended, order: .reverse),
            KeyPathComparator(\.popularityRank, order: .forward)
        ])
        
    }
}
