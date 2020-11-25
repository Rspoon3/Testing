//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject var manager = HealthKitManager()
    
    var body: some View {
        NavigationView{
            Form{
                Section(header: Text("Info")){
                    Text("Updates: \(manager.updates)")
                    
                    if !manager.isLoading{
                        Text("Number of challenges: \(manager.results.count)")
                        Text("Number of steps: \(manager.results.map(\.sum).reduce(0, +))")
                    }
                }
                ForEach(manager.results.sorted(by: {$0.challenge.startDate < $1.challenge.startDate})){ result in
                    Section(header: Text("\(result.challenge.title) (\(result.sum))")){
                        ForEach(result.steps){ steps in
                            HStack{
                                Text(steps.value.description)
                                Spacer()
                                Text(steps.formattedDate)
                            }
                        }
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
