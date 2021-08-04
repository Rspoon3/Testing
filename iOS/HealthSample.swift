//
//  HealthSample.swift
//  HealthSample
//
//  Created by Richard Witherspoon on 8/2/21.
//

import Foundation
import HealthKit

//Persistance
//Favorites
//Goals
//Unit
//Totals
//allDataTotal


struct AllDataTotal: Codable{
    let amount: Double
    let lastUpdated: Date
}

struct HealthSample: Identifiable{
    let id = UUID()
    let title: String
    let typeIdentifier: HKQuantityTypeIdentifier
    let sfSymbol: String
    var isFavorite: Bool
    var goal: HKQuantity?
    var unit: HKUnit
    let supportedUnits: [HKUnit]
    let data: [SampleData]
    let category: Category
    let chartIntervals: [ChartInterval]
    var allDataTotal: AllDataTotal?
    
    init(title: String,
         typeIdentifier: HKQuantityTypeIdentifier,
         sfSymbol: String,
         isFavorite: Bool = false,
         goal: HKQuantity? = nil,
         unit: HKUnit,
         supportedUnits: [HKUnit],
         category: Category,
         chartIntervals: [ChartInterval],
         data: [SampleData] = []
    ) {
        
        self.title = title
        self.typeIdentifier = typeIdentifier
        self.sfSymbol = sfSymbol
        self.isFavorite = isFavorite
        self.goal = goal
        self.unit = unit
        self.supportedUnits = supportedUnits
        self.category = category
        self.chartIntervals = chartIntervals
        self.data = data
    }
}

extension HealthSample{
    static let all: [HealthSample] = [.distanceWalkingRunning, .swimmingDistance, .steps]
    
    static let distanceWalkingRunning = HealthSample(title: "Walking/Running",
                                                     typeIdentifier: .distanceWalkingRunning,
                                                     sfSymbol: "running96",
                                                     isFavorite: true,
                                                     goal: HKQuantity(unit: .mile(), doubleValue: 10),
                                                     unit: Locale.current.usesMetricSystem ? .meterUnit(with: .kilo) : .mile(),
                                                     supportedUnits: [.meterUnit(with: .kilo), .meter(), .mile(), .foot()],
                                                     category: .activity,
                                                     chartIntervals: [.hour, .day, .month, .sixMonths, .year],
                                                     data: Array(1..<100).map{ i -> SampleData in
        let num = Double.random(in: 1...12)
        let date = Date.now.addingTimeInterval(TimeInterval(-i * 86_400))
        return SampleData(date: date, value: num)
    })
    
    static let swimmingDistance = HealthSample(title: "Swimming Distance",
                                               typeIdentifier: .distanceSwimming,
                                               sfSymbol: "swimming100",
                                               unit: Locale.current.usesMetricSystem ? .meter() : .yard(),
                                               supportedUnits: [.meterUnit(with: .kilo), .meter(), .mile(), .yard()],
                                               category: .activity,
                                               chartIntervals: [.day, .month, .sixMonths, .year],
                                               data: Array(1..<100).map{ i -> SampleData in
        let num = Double.random(in: 1...12)
        let date = Date.now.addingTimeInterval(TimeInterval(-i * 86_400))
        return SampleData(date: date, value: num)
    })
    
    static let steps = HealthSample(title: "Steps",
                                    typeIdentifier: .stepCount,
                                    sfSymbol: "walking96",
                                    unit: .count(),
                                    supportedUnits: [.count()],
                                    category: .activity,
                                    chartIntervals: [.day, .month, .sixMonths, .year],
                                    data: Array(1..<100).map{ i -> SampleData in
        let num = Double.random(in: 1000...22_000)
        let date = Date.now.addingTimeInterval(TimeInterval(-i * 86_400))
        return SampleData(date: date, value: num)
    })
}



struct HealthSampleCodable: Codable, Identifiable{
    let id = UUID()
    let title: String
    let typeIdentifier: HKQuantityTypeIdentifier
    var isFavorite: Bool
    let sfSymbol: String = "person"

    enum CodingKeys: String, CodingKey {
        case title
        case isFavorite
        case typeIdentifier
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)

        let typeIdentifierData = try container.decode(Data.self, forKey: .typeIdentifier)
        typeIdentifier = try (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(typeIdentifierData) as! HKQuantityTypeIdentifier)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(isFavorite, forKey: .isFavorite)

        
        let typeIdentifierData = try NSKeyedArchiver.archivedData(withRootObject: typeIdentifier, requiringSecureCoding: false)
        try container.encode(typeIdentifierData, forKey: .typeIdentifier)
    }
    
    init(title: String, typeIdentifier: HKQuantityTypeIdentifier, isFavorite: Bool){
        self.title = title
        self.typeIdentifier = typeIdentifier
        self.isFavorite = isFavorite
    }
}
