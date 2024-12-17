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
    let distance: Double
    let elapsedTime: String
    let speed: Double
    
    var formattedSpeed: String {
        let measurement = Measurement(value: speed, unit: UnitSpeed.kilometersPerHour)
        return measurement.formatted(.measurement(width: .abbreviated))
    }
    
    var formattedDistance: String {
        let measurement = Measurement(value: distance, unit: UnitLength.miles)
        return measurement.formatted(
            .measurement(
                width: .abbreviated,
                usage: .road,
                numberFormatStyle: .number.precision(.fractionLength(2))
            )
        )
    }
    
    var formattedPower: String {
        let measurement = Measurement(value: Double(power), unit: UnitPower.watts)
        return measurement.formatted()
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
                    MetricTile(label: "Distance", value: formattedDistance)
                    MetricTile(label: "Speed", value: formattedSpeed)
                    MetricTile(label: "Elapsed Time", value: elapsedTime)
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
        power: 224,
        distance: 1.17,
        elapsedTime: "13:54",
        speed: 24.23432
    )
}
