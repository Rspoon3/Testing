//
//  MetricContentView.swift
//  Testing
//
//  Created by Ricky on 12/17/24.
//

import SwiftUI

struct MetricContentView: View {
    let cadence: Int
    let resistance: Int
    let power: Int
    let power2: Int
    let distance: Double
    let elapsedTime: String
    let speed: Int
    let heartRate: Int?
    private let start = Calendar.current.startOfDay(for: .now)
    
    var formattedSpeed: String {
        let measurement = Measurement(value: Double(speed), unit: UnitSpeed.kilometersPerHour)
        return measurement.formatted(.measurement(width: .abbreviated))
    }
    
    var formattedDistance: String {
        let measurement = Measurement(value: distance, unit: UnitLength.kilometers)
        return measurement.formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(2))
            )
        )
    }
    
    var formattedPower: String {
        let measurement = Measurement(value: Double(power), unit: UnitPower.watts)
        return measurement.formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(0))
            )
        )
    }
    
    var formattedPower2: String {
        let measurement = Measurement(value: Double(power2), unit: UnitPower.watts)
        return measurement.formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(0))
            )
        )
    }

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Text("Echelon Bike Metrics")
                .font(.title2)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    MetricTile(
                        label: "Cadence",
                        value: "\(cadence) RPM",
                        animationValue: Double(cadence)
                    )
                    
                    MetricTile(
                        label: "Resistance",
                        value: "\(resistance)",
                        animationValue: Double(resistance)
                    )
                    
                    MetricTile(
                        label: "Power",
                        value: formattedPower,
                        animationValue: Double(power)
                    )
                    MetricTile(
                        label: "Power2",
                        value: formattedPower2,
                        animationValue: Double(power2)
                    )
                    MetricTile(
                        label: "Distance",
                        value: formattedDistance,
                        animationValue: distance
                    )
                    MetricTile(
                        label: "Speed",
                        value: formattedSpeed,
                        animationValue: Double(speed)
                    )
                    
                    MetricTile(
                        label: "Elapsed Time",
                        value: elapsedTime,
                        animationValue: nil
                    )

                    if let heartRate {
                        MetricTile(
                            label: "Heart Rate",
                            value: "\(heartRate) BPM",
                            animationValue: Double(heartRate)
                        )
                    }
                }
            }
            .contentMargins(16, for: .scrollContent)
        }
    }
}

#Preview {
    MetricContentView(
        cadence: 37,
        resistance: 14,
        power: 88,
        power2: 54,
        distance: 0.18761707,
        elapsedTime: "13:54",
        speed: 24,
        heartRate: 154
    )
}

struct PausableTimerView: View {
    @Binding var isRunning: Bool
    @Binding var startTime: Date
    @Binding var elapsedTime: TimeInterval
    
    var body: some View {
        VStack {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                let currentTime = isRunning ? context.date : startTime
                let totalElapsedTime = isRunning ? elapsedTime + currentTime.timeIntervalSince(startTime) : elapsedTime
                Text(formatTime(totalElapsedTime))
                    .monospaced()
                    .contentTransition(.numericText(value: totalElapsedTime))
                    .animation(.default, value: totalElapsedTime)
            }
            .padding()
            
            HStack {
                Button {
                    if isRunning {
                        // Pause the timer
                        elapsedTime += Date().timeIntervalSince(startTime)
                    } else {
                        // Start or resume the timer
                        startTime = Date()
                    }
                    isRunning.toggle()
                } label: {
                    Text(isRunning ? "Pause" : "Start")
                        .frame(width: 100, height: 50)
                        .background(isRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
    
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours == 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
}
