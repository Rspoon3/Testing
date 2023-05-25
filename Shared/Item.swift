//
//  Item.swift
//  Testing
//
//  Created by Richard Witherspoon on 5/25/23.
//

import Foundation

struct Item: Identifiable {
    let id: Int
    let rank: Int?
    let startDate: Date?
    let pointsEarned: Int
    
    static var previewData: [Item] {
        let now = Date.now
        
        return [
            Item(id: 0, rank: nil, startDate: nil, pointsEarned: 0),
            Item(id: 1, rank: 4, startDate: nil, pointsEarned: 1),
            Item(id: 2, rank: 5, startDate: nil, pointsEarned: 2),
            Item(id: 3, rank: 8, startDate: nil, pointsEarned: 3),
            Item(id: 4, rank: 1, startDate: nil, pointsEarned: 4),
            Item(id: 5, rank: nil, startDate: nil, pointsEarned: 5),
            Item(id: 6, rank: nil, startDate: nil, pointsEarned: 15),
            Item(id: 7, rank: nil, startDate: nil, pointsEarned: 35),
            Item(id: 8, rank: nil, startDate: nil, pointsEarned: 2),
            Item(id: 9, rank: nil, startDate: now, pointsEarned: 6),
            Item(id: 10, rank: nil, startDate: now, pointsEarned: 6),
            Item(id: 11, rank: nil, startDate: now, pointsEarned: 2),
            Item(id: 12, rank: nil, startDate: now, pointsEarned: 6),
            Item(id: 13, rank: nil, startDate: now, pointsEarned: 6),
            Item(id: 14, rank: nil, startDate: now, pointsEarned: 4),
            Item(id: 15, rank: nil, startDate: now, pointsEarned: 14),
            Item(id: 16, rank: nil, startDate: now, pointsEarned: 6),
            Item(id: 17, rank: nil, startDate: now.addingTimeInterval(10 * 86400), pointsEarned: 7),
            Item(id: 18, rank: 79, startDate: now.addingTimeInterval(100 * 86400), pointsEarned: 8),
            Item(id: 19, rank: 79, startDate: now.addingTimeInterval(7 * 86400), pointsEarned: 9),
            Item(id: 20, rank: nil, startDate: now.addingTimeInterval(2 * 86400), pointsEarned: 8),
            Item(id: 21, rank: nil, startDate: now.addingTimeInterval(1 * 86400), pointsEarned: 1),
            Item(id: 22, rank: nil, startDate: now.addingTimeInterval(1 * 86400), pointsEarned: 8),
            Item(id: 23, rank: nil, startDate: now.addingTimeInterval(1 * 86400), pointsEarned: 9),
            Item(id: 24, rank: nil, startDate: now.addingTimeInterval(1 * 86400), pointsEarned: 8),
        ]
    }
}


extension Array where Element == Item {
    func sortedByKeyPath() -> [Item] {
        sorted(using: [
            KeyPathComparator(\.rank, order: .reverse),
            KeyPathComparator(forwardOptionalLastUsing: \.startDate),
            KeyPathComparator(\.pointsEarned, order: .reverse)
        ])
    }
}
