//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State var samples = UserDefaults.standard.array(forKey: "data") as? [HealthSampleCodable] ?? []
    
    var body: some View {
        NavigationView{
            List($samples){ $sample in
                Button {
                    sample.isFavorite.toggle()
                    
                    if let encoded = try? JSONEncoder().encode(samples) {
                        UserDefaults.standard.set(encoded, forKey: "data")
                    }
                } label: {
                    Label(sample.title, systemImage: sample.sfSymbol)
                        .symbolVariant(sample.isFavorite ? .fill : .none)
                }
            }
            .navigationTitle("Samples")
        }
        .navigationViewStyle(.stack)
        .onAppear{
            let samples = [
                HealthSampleCodable(title: "Steps",
                                    typeIdentifier: .stepCount,
                                    isFavorite: true),
                HealthSampleCodable(title: "Cycling",
                                    typeIdentifier: .distanceCycling,
                                    isFavorite: false),
                HealthSampleCodable(title: "Walking/Running",
                                    typeIdentifier: .distanceWalkingRunning,
                                    isFavorite: true),
            ]
            
            if let data = UserDefaults.standard.data(forKey: "data") {
                if let decoded = try? JSONDecoder().decode([HealthSampleCodable].self, from: data) {
                    self.samples = decoded
                }
                print("Have samples")
            } else {
                print("Creating samples")
                if let encoded = try? JSONEncoder().encode(samples) {
                    UserDefaults.standard.set(encoded, forKey: "data")
                    self.samples = samples
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
