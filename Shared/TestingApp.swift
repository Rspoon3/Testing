//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import SwiftData

@main
struct TestingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print(URL.applicationSupportDirectory.path(percentEncoded: false))
                }
        }
        .modelContainer(
            for: [
                Item.self,
                MassUnit.self
            ]
        )
    }
}


@Model
public class Item {
    public let title: String
    @Relationship(deleteRule: .cascade) public let massUnit: MassUnit
    
    init(
        title: String,
        massUnit: MassUnit
    ) {
        self.title = title
        self.massUnit = massUnit
    }
}

public enum WOUnitMass: Int, Codable {
    case pounds = 0
    case kilograms = 1
     
    public var unitMass: UnitMass {
        switch self {
        case .pounds:
            return .pounds
        case .kilograms:
            return .kilograms
        }
    }
}

@Model
public final class MassUnit {
    private let pounds: Double
    private let unit: WOUnitMass
    
    public var measurement: Measurement<UnitMass> {
        let pounds = Measurement(value: pounds, unit: UnitMass.pounds)
        
        switch unit {
        case .pounds:
            return pounds
        case .kilograms:
            return pounds.converted(to: .kilograms)
        }
    }

    init(weight: Double, unit: WOUnitMass) {
        self.unit = unit

        switch unit {
        case .pounds:
            self.pounds = weight
        case .kilograms:
            let kilograms = Measurement(value: weight, unit: UnitMass.kilograms)
            self.pounds = kilograms.converted(to: .pounds).value
        }
    }
}
