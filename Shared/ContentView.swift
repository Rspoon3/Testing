//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject var manager = HealthKitManager()
    
    var body: some View {
        NavigationView{
            List(manager.steps, id: \.self){ step in
                Text(step.description)
            }
            .overlay(
                ProgressView()
                    .scaleEffect(1.5)
                    .opacity(manager.isLoading ? 1 : 0)
            )
            .navigationTitle("Steps")
            .toolbar{
                ToolbarItem(placement: .confirmationAction){
                    Button("Get steps"){
                        manager.getTotalStepsEachDayOverTheCourseOfThisWeek()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


//Useful articles
//https://www.devfright.com/the-healthkit-hkstatisticsquery/
//https://www.devfright.com/how-to-use-the-hkstatisticscollectionquery/
//https://www.devfright.com/healthkit/
class HealthKitManager: ObservableObject{
    let healthStore = HKHealthStore()
    let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    @Published var isLoading = false
    @Published var steps = [Int]()
    
    init() {
        let steps = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let healthKitTypesToRead: Set<HKSampleType> = [steps]

        healthStore.requestAuthorization(toShare: nil, read: healthKitTypesToRead) { (success, error) in
            if let error = error{
                print("Error: \(error)")
            }
            print(success)
        }
    }
    
    func getIndividualStepSamplesForTheLastMonth() {
        let now = Date()
        let cal = Calendar.current
        let sevenDaysAgo = cal.date(byAdding: .month, value: -1, to: now)!
        let startDate = cal.startOfDay(for: sevenDaysAgo)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictStartDate, .strictEndDate])

        let query = HKSampleQuery(sampleType: stepsType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples,
                  let results = samples as? [HKQuantitySample]
            else {
                return
            }
            
            print(results.count)
            
            for result in results{
                let value = result.quantity.doubleValue(for: .count())
                
                DispatchQueue.main.async{
                    self.steps.append(Int(value))
                    if result == results.last{
                        self.isLoading = false
                    }
                }
            }
        }
        
        isLoading = true
        healthStore.execute(query)
    }

    func getTotalStepsEver() {
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: nil, options: .cumulativeSum) { (query, statistics, error) in
            DispatchQueue.main.async{
                self.isLoading = false
            }
            if let error = error{
                print("Error: \(error)")
            } else if let statistics = statistics{
                let sum = Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                print("Start Date: ", statistics.startDate)
                print("End Date: ", statistics.endDate)
                print("Sum: \(sum)")
                            
                DispatchQueue.main.async{
                    self.steps.append(sum)
                }
            }
        }
        
        isLoading = true
        healthStore.execute(query)
    }
    
    func getTodaysSteps(){
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            DispatchQueue.main.async{
                self.isLoading = false
            }
            guard
                let result = result,
                let sumQuantity = result.sumQuantity()
            else { return }
            let sum = Int(sumQuantity.doubleValue(for: .count()))
            
            print("Sum: \(sum)")
            DispatchQueue.main.async{
                self.steps.append(sum)
            }
        }
        
        isLoading = true
        healthStore.execute(query)
    }
    
    func getTotalStepsEachDayOverTheCourseOfThisWeek(){
        let now = Date()
        let cal = Calendar.current
        let sevenDaysAgo = cal.date(byAdding: .day, value: -7, to: now)!
        let startDate = cal.startOfDay(for: sevenDaysAgo)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [.strictStartDate, .strictEndDate])
        
        var interval = DateComponents()
        interval.day = 1
        
        // start from midnight
        let anchorDate = cal.startOfDay(for: now)
       
        let query = HKStatisticsCollectionQuery(
            quantityType: stepsType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        
        query.initialResultsHandler = { query, collection, error in
            guard let collection = collection else {
                return
            }
            
            collection.enumerateStatistics(from: startDate, to: now){ (result, stop) in
                guard let sumQuantity = result.sumQuantity() else {
                    return
                }
                let totalStepForADay = Int(sumQuantity.doubleValue(for: .count()))
                let formatter = DateFormatter()
                formatter.setLocalizedDateFormatFromTemplate("MM-dd hh:mm:ss a")
                
                print("Total Step For A Day: \(totalStepForADay) :\(formatter.string(from: result.startDate)) - \(formatter.string(from: result.endDate))")
                DispatchQueue.main.async{
                    self.steps.insert(totalStepForADay, at: 0)
                    if result == collection.statistics().last{
                        self.isLoading = false
                        print("\n\n")
                    }
                }
            }
        }
        
        
        
        query.statisticsUpdateHandler = { query, statistics, collection, error in
            guard let collection = collection else {
                return
            }
            
            DispatchQueue.main.async{
                self.isLoading = true
                self.steps.removeAll()
            }
            
            collection.enumerateStatistics(from: startDate, to: now){ (result, stop) in
                guard let sumQuantity = result.sumQuantity() else {
                    return
                }
                let totalStepForADay = Int(sumQuantity.doubleValue(for: .count()))
                let formatter = DateFormatter()
                formatter.setLocalizedDateFormatFromTemplate("MM-dd hh:mm:ss a")
                
                print("Total Step For A Day: \(totalStepForADay) :\(formatter.string(from: result.startDate)) - \(formatter.string(from: result.endDate))")
                DispatchQueue.main.async{
                    self.steps.insert(totalStepForADay, at: 0)
                    if result == collection.statistics().last{
                        self.isLoading = false
                    }
                }
            }
        }
        
        isLoading = true
        healthStore.execute(query)
    }
}
