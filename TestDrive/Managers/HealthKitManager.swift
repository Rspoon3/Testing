//
//  HealthKitManager.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/24/20.
//

import SwiftUI
import HealthKit

//Useful articles
//https://www.devfright.com/the-healthkit-hkstatisticsquery/
//https://www.devfright.com/how-to-use-the-hkstatisticscollectionquery/
//https://www.devfright.com/healthkit/
class HealthKitManager: ObservableObject{
    let healthStore = HKHealthStore()
    let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let fallType  = HKQuantityType.quantityType(forIdentifier: .numberOfTimesFallen)!
    @Published var isLoading = false
    @Published var results = [Results]()
    @Published var updates = 0
    
    init() {
        let steps = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let healthKitTypesToRead: Set<HKSampleType> = [steps, fallType]
        
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypesToRead) { (success, error) in
            if let error = error{
                print("Error: \(error)")
            } else if success{
                let mockDate = MockDataManager()
                
                for tuple in mockDate.fetchDates(){
                    self.runQuery(for: tuple.0, from: tuple.1, to: tuple.2)
                }
            }
        }
    }
    
    
    func runQuery(for challenge: Challenge, from startDate: Date, to endDate: Date){
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate, .strictEndDate])
        var steps = [Steps]()
        var interval = DateComponents()
        interval.day = 1
        
        // start from midnight
        let anchorDate = Calendar.current.startOfDay(for: endDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepsType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { query, collection, error in
            guard let collection = collection else {
                print("No collection")
                DispatchQueue.main.async{
                    self.isLoading = false
                }
                return
            }
            
            for statistic in collection.statistics(){
                guard let sumQuantity = statistic.sumQuantity() else {
                    return
                }

                let totalStepsForADay = Int(sumQuantity.doubleValue(for: .count()))
                let step = Steps(date: statistic.startDate, value: totalStepsForADay)
                steps.insert(step, at: 0)
            }
            
            DispatchQueue.main.async{
                self.results.append(Results(steps: steps, challenge: challenge))
                self.isLoading = false
            }
        }
        
        DispatchQueue.main.async{
            self.isLoading = true
        }
        healthStore.execute(query)
    }
}


//Steps
//1. Fetch the latest record to get the last push date
//2. Get all challenges since last push date
//3. Run logic above

//4a. If last push date is NOT today, upload all results
//4b. If last push date is today,
    //4b1. Push all results except who's date is today
    //4b2. Fetch all records who's date is today
    //4b3. Sum all of those record values
    //4b4. Add the new result with todays date to that sum
    //4b5. Delete all fetched records from 3b2.
    //4b6. Add a new record with the value from 3b4.
