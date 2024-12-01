//
//  USState.swift
//  Testing (iOS)
//
//  Created by Ricky on 11/30/24.
//

import Foundation

struct USState: Codable, Identifiable {
    let id: UUID
    let title: String
    let tagline: String
    let funDescription: String
    let neatFact: String
    let capital: String
    let motto: String
    let yearFounded: Int
    let estimatedPopulation: Int
    let heroImage: String
    let licensePlateImage: String
    let stateNumber: Int
    let latitude: Double
    let longitude: Double
}

extension USState {
    static let newHampshire = USState(
        id: UUID(),
        title: "New Hampshire",
        tagline: "The Granite State",
        funDescription: "New Hampshire is known for its breathtaking White Mountains and its pivotal role in U.S. presidential primaries.",
        neatFact: "New Hampshire was the first state to establish its own constitution.",
        capital: "Concord",
        motto: "Live Free or Die",
        yearFounded: 1788,
        estimatedPopulation: 1377529,
        heroImage: "placeholder_for_hero_image_url",
        licensePlateImage: "placeholder_for_license_plate_image_url",
        stateNumber: 9,
        latitude: 43.2081,
        longitude: -71.5376
    )
}
