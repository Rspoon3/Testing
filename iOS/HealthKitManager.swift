//
//  HealthKitManager.swift
//  HealthKitManager
//
//  Created by Richard Witherspoon on 8/1/21.
//

import Foundation
import HealthKit


//Useful articles
//https://www.devfright.com/the-healthkit-hkstatisticsquery/
//https://www.devfright.com/how-to-use-the-hkstatisticscollectionquery/
//https://www.devfright.com/healthkit/


@MainActor
class HealthKitManager: ObservableObject{
    let healthStore = HKHealthStore()
    let cal = Calendar.current
    private let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    var errorMessage: String?
    
    @Published var totalDataEver = 0.0
    @Published var todaysData = 0.0
    @Published var thisWeeksDataGroupedByDay = [SampleData]()
    @Published private(set) var state = State.loading
    
    enum State {
        case loading
        case failed(Error)
        case loaded
    }
    
    func loadData(authorize: Bool) async{
        let start = CFAbsoluteTimeGetCurrent()
                
        do {
            if authorize{
                try await requestAuthorization()
            }
            
            totalDataEver = try await getTotalDataEver()
            todaysData = try await getTodaysData()
            thisWeeksDataGroupedByDay = try await getThisWeeksDataGroupedByDay()
        } catch{
            state = .failed(error)
        }
        
        state = .loaded
        
        let diff = CFAbsoluteTimeGetCurrent() - start
        print("Loading took \(diff.formatted(.number.precision(.significantDigits(3)))) seconds.")
    }
    
    func requestAuthorization() async throws {
        do {
            let types: Set<HKSampleType> = [distance]
            try await healthStore.requestAuthorization(toShare: Set(), read: types)
        } catch {
            throw HKError.notAuthorized(error: error)
        }
    }
    
    func getTotalDataEver() async throws -> Double{
        let statistics = try await healthStore.executeHKStatisticsQuery(type: distance,
                                                                        options: .cumulativeSum).1
        
        guard let sum = statistics.sumQuantity() else {
            throw HKError.noSumQuantity
        }
        
        return sum.doubleValue(for: .mile())
    }
    
    func getTodaysData() async throws -> Double{
        let now = Date()
        let startOfDay = cal.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay,
                                                    end: now,
                                                    options: .strictStartDate)
        let statistics = try await healthStore.executeHKStatisticsQuery(type: distance,
                                                                        predicate: predicate,
                                                                        options: .cumulativeSum).1
        
        guard let sum = statistics.sumQuantity() else {
            throw HKError.noSumQuantity
        }
        
        let units = try await healthStore.preferredUnits(for: [distance])
        let preferredUnit = units.first!.value
        let value = sum.integerValue(for: preferredUnit)
        

        let formatter = LengthFormatter()
        formatter.unitStyle = .long
        
        var lengthFormatterUnit = HKUnit.lengthFormatterUnit(from: preferredUnit)
        print(formatter.string(fromValue: Double(value), unit: lengthFormatterUnit))
                
        let feetValue = sum.doubleValue(for: .foot())
        lengthFormatterUnit = HKUnit.lengthFormatterUnit(from: .foot())
        print(formatter.string(fromValue: feetValue, unit: lengthFormatterUnit))
        
        return sum.doubleValue(for: .mile())
    }
    
    func getThisWeeksDataGroupedByDay() async throws -> [SampleData]{
        let now = Date()
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: now)!
        let startDate = cal.startOfDay(for: sevenDaysAgo)
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: nil,
                                                    options: [.strictStartDate])
        let interval = DateComponents(day: 1)
        let anchorDate = cal.startOfDay(for: now)// start from midnight
        let statistics = try await healthStore.executeHKStatisticsCollectionQuery(type: distance,
                                                                                  predicate: predicate,
                                                                                  options: .cumulativeSum,
                                                                                  anchorDate: anchorDate,
                                                                                  intervalComponents: interval).1.statistics()
        
        return try statistics.compactMap{ statistic -> SampleData in
            guard let sum = statistic.sumQuantity() else {
                throw HKError.noSumQuantity
            }
            
            let totalForADay = sum.doubleValue(for: .mile())
            
            return SampleData(date: statistic.startDate, value: totalForADay)
        }
    }
}
