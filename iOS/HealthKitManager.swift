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
    private let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    var errorMessage: String?
    
    @Published var individualStepsLastWeek = [Data]()
    @Published var totalStepsEver = 0
    @Published var todaysSteps = 0
    @Published var totalStepsEachDayThisWeek = [Data]()
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
            
            individualStepsLastWeek = try await getIndividualStepFromLastWeek()
            totalStepsEver = try await getTotalStepsEver()
            todaysSteps = try await getTodaysSteps()
            totalStepsEachDayThisWeek = try await getTotalStepsEachDayOverTheCourseOfThisWeek()
        } catch{
            state = .failed(error)
        }
        
        state = .loaded
        
        let diff = CFAbsoluteTimeGetCurrent() - start
        print("Loading took \(diff.formatted(.number.precision(.significantDigits(3)))) seconds.")
    }
    
    func requestAuthorization() async throws {
        do {
            let types: Set<HKSampleType> = [stepsType]
            try await healthStore.requestAuthorization(toShare: Set(), read: types)
        } catch {
            throw HKError.notAuthorized(error: error)
        }
    }
    
    func getTotalStepsEver() async throws -> Int{
        let statistics = try await healthStore.executeHKStatisticsQuery(type: stepsType,
                                                                        options: .cumulativeSum).1
        
        guard let sum = statistics.sumQuantity() else {
            throw HKError.noSumQuantity
        }
        
        return sum.integerValue(for: .count())
    }
    
    func getTodaysSteps() async throws -> Int{
        let now = Date()
        let startOfDay = cal.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay,
                                                    end: now,
                                                    options: .strictStartDate)
        let statistics = try await healthStore.executeHKStatisticsQuery(type: stepsType,
                                                                        predicate: predicate,
                                                                        options: .cumulativeSum).1
        
        guard let sum = statistics.sumQuantity() else {
            throw HKError.noSumQuantity
        }
        
        return sum.integerValue(for: .count())
    }
    
    func getIndividualStepFromLastWeek() async throws -> [Data]{
        let now = Date()
        let sevenDaysAgo = cal.date(byAdding: .weekOfYear, value: -1, to: now)!
        let startDate = cal.startOfDay(for: sevenDaysAgo)
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: nil,
                                                    options: [.strictStartDate, .strictEndDate])
        
        
        let samples = try await healthStore.executeHKSampleQuery(type: stepsType, predicate: predicate).1
        
        return samples.map{ sample in
            let value = sample.quantity.integerValue(for: .count())
            let date = sample.startDate
            return Data(date: date, value: value)
        }
    }
    
    func getTotalStepsEachDayOverTheCourseOfThisWeek() async throws -> [Data]{
        let now = Date()
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: now)!
        let startDate = cal.startOfDay(for: sevenDaysAgo)
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: nil,
                                                    options: [.strictStartDate])
        let interval = DateComponents(day: 1)
        let anchorDate = cal.startOfDay(for: now)// start from midnight
        let statistics = try await healthStore.executeHKStatisticsCollectionQuery(type: stepsType,
                                                                                  predicate: predicate,
                                                                                  options: .cumulativeSum,
                                                                                  anchorDate: anchorDate,
                                                                                  intervalComponents: interval).1.statistics()
        
        return try statistics.compactMap{ statistic -> Data in
            guard let sum = statistic.sumQuantity() else {
                throw HKError.noSumQuantity
            }
            
            let totalStepsForADay = sum.integerValue(for: .count())
            
            return Data(date: statistic.startDate, value: totalStepsForADay)
        }
    }
}
