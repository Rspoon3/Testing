//
//  HealthKitManager.swift
//  Testing
//
//  Created by Ricky on 1/1/25.
//

import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    // Check if HealthKit is available and request authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailableOnDevice
        }
        
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        try await healthStore.requestAuthorization(toShare: [], read: [weightType])
    }
    
    // Query for the most recent weight sample
      func fetchMostRecentWeight() async throws -> WeightSample? {
          let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
          
          let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .reverse)
          
          let query = HKSampleQueryDescriptor(
              predicates: [.quantitySample(type: weightType, predicate: nil)],
              sortDescriptors: [sortDescriptor],
              limit: 1 // Fetch the most recent sample
          )
          
          let samples = try await query.result(for: healthStore)
          
          guard let sample = samples.first else {
              return nil
          }
          
          let weightInLbs = sample.quantity.doubleValue(for: HKUnit.pound())
          return WeightSample(
            date: sample.startDate,
            weight: weightInLbs
          )
      }
    
    // Query for the last date the weight was at or below a given value
    func fetchLastDateForWeight(atOrBelow targetWeight: Double) async throws -> WeightSample? {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sortDescriptor = SortDescriptor(\HKQuantitySample.startDate, order: .reverse)
        
        let targetQuantity = HKQuantity(unit: HKUnit.pound(), doubleValue: targetWeight)
        let predicate = NSPredicate(format: "%K <= %@", HKPredicateKeyPathQuantity, targetQuantity)

        let query = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: weightType, predicate: predicate)],
            sortDescriptors: [sortDescriptor],
            limit: 1
        )
        
        let samples = try await query.result(for: healthStore)
        print(samples.count, targetWeight, samples)
        guard let sample = samples.first else {
            return nil
        }
        
        let weight = sample.quantity.doubleValue(for: HKUnit.pound())
        if weight <= targetWeight {
            return WeightSample(
                date: sample.startDate,
                weight: weight
            )
        }
        
        return nil
    }
}

// HealthKit Error Handling
enum HealthKitError: Error {
    case notAvailableOnDevice
    case dataNotAvailable
}

struct WeightSample {
    let date: Date
    let weight: Double
}
