//
//  HealthKitManager.swift
//  Testing (iOS)
//
//  Created by Ricky Witherspoon on 4/15/25.
//

import Foundation
import HealthKit

struct HealthKitManager {
    private let healthStore = HKHealthStore()
    private let calendar = Calendar.current
    
    enum HKError: Error {
        case noResults
    }
    
    func rings() async throws -> ActivityRingValues {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.calendar = calendar

        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: components, end: components)
        let descriptor = HKActivitySummaryQueryDescriptor(predicate: predicate)
        let results = try await descriptor.result(for: healthStore)
        
        guard let summary = results.first else {
            throw HKError.noResults
        }
        
        return ActivityRingValues(summary: summary)
    }
    
    func stepCount() async throws -> Int {
        // Create a predicate for today's samples.
        let startDate = calendar.startOfDay(for: .now)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)
        let today = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        // Create the query descriptor.
        let stepType = HKQuantityType(.stepCount)
        let stepsToday = HKSamplePredicate.quantitySample(type: stepType, predicate:today)
        let sumOfStepsQuery = HKStatisticsQueryDescriptor(predicate: stepsToday, options: .cumulativeSum)

        let stepCount = try await sumOfStepsQuery.result(for: healthStore)?
            .sumQuantity()?
            .doubleValue(for: HKUnit.count())

        return Int(stepCount ?? 0)
    }
    
    func mindfulnessMinutes() async throws -> Int {
        let type = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: .now,
            options: .strictEndDate
        )
        
        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: samples)
            }

            healthStore.execute(query)
        }
        
        let totalMinutes = samples.reduce(0.0) { total, sample in
            total + sample.endDate.timeIntervalSince(sample.startDate) / 60
        }
        
        return Int(totalMinutes)
    }
}
