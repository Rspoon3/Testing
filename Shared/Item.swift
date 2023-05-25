//
//  Item.swift
//  Testing
//
//  Created by Richard Witherspoon on 5/25/23.
//

import Foundation

struct Item: Identifiable {
    let id = UUID()
    let isFavorite: Bool
    let favoriteRank: Int?
    let isRecommended: Bool
    let popularityRank: Int
    
    static let previewData: [Item] = [
        Item(isFavorite: true, favoriteRank: 14, isRecommended: false, popularityRank: 10),
        Item(isFavorite: true, favoriteRank: 5, isRecommended: false, popularityRank: 20),
        Item(isFavorite: true, favoriteRank: 34, isRecommended: true, popularityRank: 30),
        Item(isFavorite: true, favoriteRank: 5, isRecommended: true, popularityRank: 5),
        Item(isFavorite: true, favoriteRank: 214, isRecommended: true, popularityRank: 3),
        Item(isFavorite: true, favoriteRank: 554, isRecommended: true, popularityRank: 3),
        Item(isFavorite: true, favoriteRank: 234, isRecommended: true, popularityRank: 3),
        Item(isFavorite: true, favoriteRank: 1, isRecommended: false, popularityRank: 5),
        Item(isFavorite: true, favoriteRank: 0, isRecommended: false, popularityRank: 5),
        Item(isFavorite: false, favoriteRank: nil, isRecommended: false, popularityRank: 1),
        Item(isFavorite: false, favoriteRank: nil, isRecommended: true, popularityRank: 33),
        Item(isFavorite: false, favoriteRank: nil, isRecommended: true, popularityRank: 33),
        Item(isFavorite: false, favoriteRank: nil, isRecommended: false, popularityRank: 10),
        Item(isFavorite: false, favoriteRank: nil, isRecommended: true, popularityRank: 45),
        Item(isFavorite: false, favoriteRank: nil, isRecommended: false, popularityRank: 90),
        Item(isFavorite: false, favoriteRank: nil, isRecommended: false, popularityRank: 10),
        Item(isFavorite: false, favoriteRank: nil, isRecommended: true, popularityRank: 40),
    ]
}


extension Array where Element == Item {
    func sortedByKeyPath() -> Self {
        sorted(using: [
            KeyPathComparator(\.favoriteRank, order: .forward, nilOrder: .reverse),
            KeyPathComparator(\.isRecommended, order: .reverse),
            KeyPathComparator(\.popularityRank, order: .forward)
        ])
        
    }
}
