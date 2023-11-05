//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var model = ContentViewModel()
    
    var body: some View {
        VStack {
            switch model.state {
            case .idle:
                EmptyView()
            case .exporting(let title, let progress), .importing(let title, let progress):
                ProgressView(title, value: progress)
            }
            
            Button("Export") {
                Task {
                    try? await model.authorize()
                    try? await model.export()
                }
            }
            .padding()
            
            Button("Import") {
                Task {
                    try! await model.authorize()
                    model.importFile.toggle()
                }
            }
            .padding()
        }
        .font(.largeTitle)
        .fileImporter(isPresented: $model.importFile, allowedContentTypes: [.data], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                model.importAndSave(from: urls)
            case .failure(let failure):
                print(failure.localizedDescription)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

@Observable
final class ContentViewModel {
    enum State {
        case idle
        case exporting(String, Double)
        case importing(String, Double)
    }
    var importFile = false
    var state: State = .idle
    let store = HKHealthStore()
    let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: .now)!
    let supportedIDs: [HKQuantityTypeIdentifier] = [
        .stepCount,
        .distanceSwimming,
        .distanceWalkingRunning,
        .activeEnergyBurned,
        .dietaryCalcium,
        .activeEnergyBurned,
        .basalEnergyBurned
    ]
    
//    @MainActor
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
                    
                    try! await save(data)
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
    
//    MainActor
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
        let startDate = Calendar.current.startOfDay(for: oneYearAgo)
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
        
        print("Done \(id.title)")
    }
}


extension HKQuantityTypeIdentifier {
    var title: String {
        rawValue.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "")
    }
}
