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
    let speed: Double
    let heartRate: Int?
    
    var formattedSpeed: String {
        let measurement = Measurement(value: speed, unit: UnitSpeed.kilometersPerHour)
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
                    MetricTile(label: "Cadence", value: "\(cadence) RPM")
                    MetricTile(label: "Resistance", value: "\(resistance)")
                    MetricTile(label: "Power", value: formattedPower)
                    MetricTile(label: "Power2", value: formattedPower2)
                    MetricTile(label: "Distance", value: formattedDistance)
                    MetricTile(label: "Speed", value: formattedSpeed)
                    MetricTile(label: "Elapsed Time", value: elapsedTime)

                    if let heartRate {
                        MetricTile(label: "Heart Rate", value: "\(heartRate) BPM")
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
        speed: 24.23432,
        heartRate: 154
    )
}
