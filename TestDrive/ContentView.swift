//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Charts

struct StepData: Identifiable {
    let id = UUID()
    let day: String
    let steps: Int
}

struct ContentView: View {
    let weeklySteps = [
        StepData(day: "Mon", steps: 8245),
        StepData(day: "Tue", steps: 6732),
        StepData(day: "Wed", steps: 9876),
        StepData(day: "Thu", steps: 7234),
        StepData(day: "Fri", steps: 10543),
        StepData(day: "Sat", steps: 5432),
        StepData(day: "Sun", steps: 4567)
    ]
    
    
    var body: some View {
        VStack {
            Text("Weekly Steps")
                .font(.title2)
                .fontWeight(.semibold)
            
            Chart(weeklySteps) { stepData in
                BarMark(
                    x: .value("Day", stepData.day),
                    y: .value("Steps", stepData.steps)
                )
                .foregroundStyle(by: .value("Category", "Steps"))
            }
            .chartYScale(domain: 0...(weeklySteps.map(\.steps).max() ?? 0))
            .frame(height: 300)
            .border(Color.red, width: 1)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
