//
//  HeartRateManager.swift
//  Testing
//
//  Created by Ricky on 12/17/24.
//

import HealthKit

struct HeartRate {
    let lastUpdate: Date = .now
    let value: Int
    let startDate: Date
    let endDate: Date
}

@Observable
final class HeartRateManager {
    private let healthStore = HKHealthStore()
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    
    private(set) var heartRate: HeartRate?
    
    private var heartRateQuery: HKAnchoredObjectQuery?
    
    // Request HealthKit authorization
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set<HKObjectType> = [heartRateType]
        try? await healthStore.requestAuthorization(
            toShare: [],
            read: typesToRead
        )
        
        print("HealthKit authorization granted.")
        await startHeartRateQuery()
    }
    
    // Start heart rate query for live updates
    func startHeartRateQuery() async {
        let predicate = HKQuery.predicateForSamples(
            withStart: .now,
            end: nil,
            options: HKQueryOptions()
        )

        heartRateQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, _, _, error in
            print("Initial query result received.")
            self?.processHeartRateSamples(samples, error: error)
        }
        
        heartRateQuery?.updateHandler = { [weak self] query, samples, _, _, error in
            print("Live heart rate update received.")
            self?.processHeartRateSamples(samples, error: error)
        }
        
        guard let heartRateQuery else { return }
        
        healthStore.execute(heartRateQuery)
        print("Heart rate query executed.")
        
        do {
            try await healthStore.enableBackgroundDelivery(
                for: heartRateType,
                frequency: .immediate
            )
            print("Background delivery enabled.")
        } catch {
            print("Failed to enable background delivery: \(error.localizedDescription)")
        }
    }
    
    // Process heart rate samples
    private func processHeartRateSamples(_ samples: [HKSample]?, error: Error?) {
        guard let heartRateSample = samples?.last as? HKQuantitySample else {
            print("Error fetching heart rate sample: \(error?.localizedDescription ?? "N/A")")
            return
        }
        
        let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let heartRateValue = Int(heartRateSample.quantity.doubleValue(for: heartRateUnit))
        print("Current HR: \(heartRateValue)")
        
        DispatchQueue.main.async {
            self.heartRate = .init(
                value: Int(heartRateValue),
                startDate: heartRateSample.startDate,
                endDate: heartRateSample.endDate
            )
        }
    }
}
