//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Charts

struct ContentView: View {
    @AppStorage("value") private var value: Double = 204_000
    @FocusState private var isTextFieldFocused: Bool
    
    private let targetDate: Date = {
        var components = DateComponents()
        components.year = 2029
        components.month = 1
        components.day = 20
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }()

    var body: some View {
        VStack {
            TextField("Enter Value", value: $value, format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .padding()
                .focused($isTextFieldFocused)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isTextFieldFocused = false // Dismiss the keyboard
                        }
                    }
                }
            
            Text(
                timerInterval: .now...targetDate,
                pauseTime: targetDate,
                countsDown: true,
                showsHours: true
            )
            
            
            
            TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
                let currentDate = timeline.date
                let yearFraction = calculateYearFraction(for: currentDate)
                let currentValue = yearFraction * value
                
                VStack(spacing: 20) {
                    
                    let countdownText = calculateCountdown(to: targetDate, from: currentDate)
                    
                    Text("Time Until January 20, 2028:")
                        .font(.headline)
                    
                    Text(countdownText)
                        .font(.largeTitle)
                        .bold()
                        .monospaced()
                        .padding()
                    
                    Text(
                        currentValue.formatted(
                            .currency(code: "USD").precision(.fractionLength(4))
                        )
                    )
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .monospaced()
                    .foregroundColor(.primary)
                    
                    Text("Year Progress: \(yearFraction.formatted(.percent))")
                        .monospaced()
                        .lineLimit(1)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: yearFraction) {
                        Text("Year Progress")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
                    .frame(height: 30)
                    
                    //                // Pie Chart
                    //                PieChartView(progress: yearFraction)
                    //                    .frame(width: 200, height: 200)
                }
            }
            .padding(20)
        }
    }
    
    private func calculateYearFraction(for date: Date) -> Double {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: date))!
        let endOfYear = calendar.date(byAdding: DateComponents(year: 1, second: -1), to: startOfYear)!
        
        let totalYearSeconds = endOfYear.timeIntervalSince(startOfYear)
        let elapsedSeconds = date.timeIntervalSince(startOfYear)
        
        return max(0, min(elapsedSeconds / totalYearSeconds, 1))
    }
    
    
 
    func calculateCountdown(to targetDate: Date, from currentDate: Date) -> String {
        guard targetDate > currentDate else {
            return "Event has arrived!"
        }
        
        let calendar = Calendar.current
        
        // Get the difference in years and months
        let dateComponents = calendar.dateComponents([.year, .month], from: currentDate, to: targetDate)
        
        // Adjust for day/hour/minute/second precision
        let intermediateDate = calendar.date(byAdding: dateComponents, to: currentDate)!
        let remainingComponents = calendar.dateComponents([.day, .hour, .minute, .second], from: intermediateDate, to: targetDate)

        let years = dateComponents.year ?? 0
        let months = dateComponents.month ?? 0
        let days = remainingComponents.day ?? 0
        let hours = remainingComponents.hour ?? 0
        let minutes = remainingComponents.minute ?? 0
        let seconds = remainingComponents.second ?? 0
        
        return "\(years)y \(months)m \(days)d \(hours)h \(minutes)m \(seconds)s"
    }
}


#Preview {
    ContentView()
}

struct PieChartView: View {
    var progress: Double
    
    var body: some View {
        Chart {
            // Completed portion
            SectorMark(
                angle: .value("Progress", progress * 360),
                innerRadius: .ratio(0.5),
                outerRadius: .ratio(1.0)
            )
            .foregroundStyle(Color.blue)
            
            // Remaining portion
            SectorMark(
                angle: .value("Remaining", (1 - progress) * 360),
                innerRadius: .ratio(0.5),
                outerRadius: .ratio(1.0)
            )
            .foregroundStyle(Color.gray.opacity(0.3))
        }
        .chartLegend(.hidden)
    }
}
