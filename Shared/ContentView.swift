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
            List{
                Text("Updates: \(manager.updates)")
                ForEach(manager.steps){ steps in
                    HStack{
                        Text(steps.value.description)
                        Spacer()
                        Text(steps.formattedDate)
                    }
                }
            }
            .overlay(
                ProgressView()
                    .scaleEffect(1.5)
                    .opacity(manager.isLoading ? 1 : 0)
            )
            .navigationTitle("Steps")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Steps: Identifiable{
    let id = UUID()
    let date: Date
    let value: Int
    
    var formattedDate: String{
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MM/dd/yyyy")
        return formatter.string(from: date)
    }
}


//Useful articles
//https://www.devfright.com/the-healthkit-hkstatisticsquery/
//https://www.devfright.com/how-to-use-the-hkstatisticscollectionquery/
//https://www.devfright.com/healthkit/
class HealthKitManager: ObservableObject{
    let healthStore = HKHealthStore()
    let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let fallType  = HKQuantityType.quantityType(forIdentifier: .numberOfTimesFallen)!
    @Published var isLoading = false
    @Published var steps = [Steps]()
    @Published var updates = 0
    
    init() {
        let steps = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let healthKitTypesToRead: Set<HKSampleType> = [steps, fallType]
        
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypesToRead) { (success, error) in
            if let error = error{
                print("Error: \(error)")
            } else if success{
                self.getTotalStepsEachDayOverTheCourseOfThisWeek()
            }
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
                let steps = Steps(date: result.startDate, value: Int(value))
                
                DispatchQueue.main.async{
                    self.steps.append(steps)
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
                let steps = Steps(date: Date(), value: sum)
                print("Start Date: ", statistics.startDate)
                print("End Date: ", statistics.endDate)
                print("Sum: \(sum)")
                
                DispatchQueue.main.async{
                    self.steps.append(steps)
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
            let steps = Steps(date: now, value: sum)
            
            print("Sum: \(sum)")
            DispatchQueue.main.async{
                self.steps.append(steps)
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
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: [.strictStartDate])
        
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
                print("No collection")
                DispatchQueue.main.async{
                    self.isLoading = false
                }
                return
            }
            
            collection.enumerateStatistics(from: startDate, to: Date()){ (result, stop) in
                guard let sumQuantity = result.sumQuantity() else {
                    return
                }
                
                let totalStepsForADay = Int(sumQuantity.doubleValue(for: .count()))
                let steps = Steps(date: result.startDate, value: totalStepsForADay)
                print(steps.value, steps.formattedDate)
                
                DispatchQueue.main.async{
                    self.steps.insert(steps, at: 0)
                }
            }
            
            print("initialResultsHandler done")
            DispatchQueue.main.async{
                self.isLoading = false
            }
        }
        
        
        query.statisticsUpdateHandler = { query, statistics, collection, error in
            print("In statisticsUpdateHandler...")
            guard let collection = collection else {
                print("No collection")
                DispatchQueue.main.async{
                    self.isLoading = false
                }
                return
            }
            
            DispatchQueue.main.async{
                self.isLoading = true
                self.updates += 1
                self.steps.removeAll(keepingCapacity: true)
            }
            
            collection.enumerateStatistics(from: startDate, to: Date()){ (result, stop) in
                guard let sumQuantity = result.sumQuantity() else {
                    return
                }
                
                let totalStepsForADay = Int(sumQuantity.doubleValue(for: .count()))
                let steps = Steps(date: result.startDate, value: totalStepsForADay)
                print(steps.value, steps.formattedDate)
                print("\n\n")
                
                DispatchQueue.main.async{
                    self.steps.insert(steps, at: 0)
                }
            }
            
            print("statisticsUpdateHandler done")
            DispatchQueue.main.async{
                self.isLoading = false
            }
        }
        
        
        isLoading = true
        healthStore.execute(query)
    }
}
