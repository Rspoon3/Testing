//
//  Extension+HKHealthStore.swift
//  Extension+HKHealthStore
//
//  Created by Richard Witherspoon on 8/1/21.
//

import Foundation
import HealthKit

extension HKHealthStore{
    //MARK: Private Helpers
    func executeHKSampleQuery(type: HKSampleType,
                              predicate: NSPredicate,
                              limit: Int = HKObjectQueryNoLimit,
                              sortDescriptors: [NSSortDescriptor]? = nil
    ) async throws -> (HKSampleQuery, [HKQuantitySample]) {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type,
                                      predicate: predicate,
                                      limit: limit,
                                      sortDescriptors: sortDescriptors) { (query, samples, error) in
                
                // When the query ends, check for errors.
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let samples = samples as? [HKQuantitySample]{
                    continuation.resume(returning: (query, samples))
                } else {
                    continuation.resume(throwing: HKError.noSamples)
                }
            }
            
            execute(query)
        }
    }
    
    func executeHKStatisticsQuery(type: HKQuantityType,
                                  predicate: NSPredicate? = nil,
                                  options: HKStatisticsOptions
    ) async throws -> (HKStatisticsQuery, HKStatistics) {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: options) { (query, statistics, error) in
                
                // When the query ends, check for errors.
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let statistics = statistics {
                    continuation.resume(returning: (query, statistics))
                } else {
                    continuation.resume(throwing: HKError.noStatistics)
                }
            }
            
            execute(query)
        }
    }
    
    func executeHKStatisticsCollectionQuery(type: HKQuantityType,
                                            predicate: NSPredicate? = nil,
                                            options: HKStatisticsOptions,
                                            anchorDate: Date,
                                            intervalComponents: DateComponents
    ) async throws -> (HKStatisticsCollectionQuery, HKStatisticsCollection) {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(quantityType: type,
                                                    quantitySamplePredicate: predicate,
                                                    options: options,
                                                    anchorDate: anchorDate,
                                                    intervalComponents: intervalComponents)
            
            query.initialResultsHandler = { query, collection, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let collection = collection {
                    continuation.resume(returning: (query, collection))
                } else {
                    continuation.resume(throwing: HKError.noCollections)
                }
            }
            
            execute(query)
        }
    }
}
