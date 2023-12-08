//
//  Offer.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 12/8/23.
//

import Foundation

struct Offer: Decodable, Identifiable, Sendable {
    var id: String { offerId }
    let offerId: String
    let imageUrl: String
    let points: Int
    
    static let example: Offer = Offer(
        offerId: UUID().uuidString,
        imageUrl: "https://image-resize.fetchrewards.com/deals/06e6e768e4c185342a7ff25fe1abab51b7e93da2.jpeg",
        points: Int.random(in: 1..<10_000)
    )
    
    static func examples(count: Int = 14) -> [Offer] {
        (0..<count).map { _ in
            Offer(
                offerId: UUID().uuidString,
                imageUrl: "https://image-resize.fetchrewards.com/deals/06e6e768e4c185342a7ff25fe1abab51b7e93da2.jpeg",
                points: Int.random(in: 1..<10_000)
            )
        }
    }
}
