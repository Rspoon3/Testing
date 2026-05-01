//
//  ContentViewModel.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/18/23.
//

import Foundation
import HealthKit

@Observable
@MainActor
final class ContentViewModel {
    enum State {
        case idle
        case exporting(String, Double)
        case importing(String, Double)
    }
    var importFile = false
    var state: State = .idle
    let store = HKHealthStore()
    var startDate = Calendar.current.date(
        byAdding: .weekOfYear,
        value: -1,
        to: .now
    ) ?? .now
    let supportedIDs: [HKQuantityTypeIdentifier] = [
        .stepCount,
        .distanceSwimming,
        .distanceWalkingRunning,
        .activeEnergyBurned,
        .dietaryCalcium,
        .activeEnergyBurned,
        .basalEnergyBurned
    ]
    
    func importAndSave(from urls: [URL]) {
        Task {
            let count = urls.count
            state = .importing("Starting Import", 0)
            defer { state = .idle}
            
            do {
                for (i, url) in urls.enumerated() {
                    let needTo = url.startAccessingSecurityScopedResource()
                    let sampleTitle = url.lastPathComponent
                    
                    let data = try! Data(contentsOf: url)
                    
                    try await save(data)
                    let progress = Double(i) / Double(count)
                    state = .importing("Importing \(sampleTitle)", progress)
                    print("Done importing \(sampleTitle)")
                    
                    if needTo {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func save(_ data: Data) async throws {
        let decodedSamples = try NSKeyedUnarchiver.unarchivedObject(
            ofClasses: [
                NSArray.self,
                HKQuantitySample.self
            ],
            from: data
        ) as! [HKQuantitySample]
        
        guard let first = decodedSamples.first else {
            print("EMPTY")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: nil)
        try await store.deleteObjects(of: first.sampleType, predicate: predicate)
        print("Deleted \(first.sampleType)")
        
        let samples = decodedSamples.map { sample in
            HKQuantitySample(
                type: sample.quantityType,
                quantity: sample.quantity,
                start: sample.startDate,
                end: sample.endDate
            )
        }
        
        try await store.save(samples)
    }
    
    func authorize() async throws {
        let types: Set<HKSampleType> = Set(supportedIDs.compactMap {
            HKObjectType.quantityType(forIdentifier: $0)
        })
        
        try await store.requestAuthorization(
            toShare: types,
            read: types
        )
    }
    
    func export() async throws {
        state = .exporting("Starting Export", 0)
        defer { state = .idle }
        
        let count = supportedIDs.count
        
        for (i,id) in supportedIDs.enumerated() {
            try await export(id: id)
            let progress = Double(i) / Double(count)
            state = .exporting(id.title, progress)
        }
    }
    
    private func export(id: HKQuantityTypeIdentifier) async throws {
        let type = HKQuantityType(id)
        
        let hkQueryPredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: .now,
            options: [.strictEndDate]
        )
        
        let predicate = HKSamplePredicate.quantitySample(
            type: type,
            predicate: hkQueryPredicate
        )
        
        let query = HKSampleQueryDescriptor(
            predicates: [predicate],
            sortDescriptors: []
        )
        
        let samples = try await query.result(for: store)
        
        guard !samples.isEmpty else {
            print("EMPTY")
            return
        }
        
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: samples,
            requiringSecureCoding: true
        )
        
        let directoryURL = URL.documentsDirectory.appendingPathComponent("HealthData")
        
        try FileManager.default.createDirectory(
            atPath: directoryURL.path(
                percentEncoded: false
            ),
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let sampleURL = directoryURL.appendingPathComponent(id.title)
        try data.write(to: sampleURL, options: .atomic)
        
        print("\(id.title) exported to \(sampleURL.absoluteString)")
    }
}
