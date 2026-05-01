//
//  MetricsChartView.swift
//  Testing
//
//  Created by Ricky on 12/20/24.
//

import SwiftUI
import Charts

struct MetricsChartView: View {
    var viewModel: HomeViewModel
    @State private var averages = Averages(cadence: 0, speed: 0, power: 0, resistance: 0)
    struct Averages {
        let cadence: Int
        let speed: Int
        let power: Int
        let resistance: Int
    }
    
    var body: some View {
        VStack {
            // Chart for Cadence and Speed
            // Chart for Cadence and Speed
            Chart(viewModel.historicalMetrics) { metric in
                if let cadence = metric.cadence, cadence != 0 {
                    LineMark(
                        x: .value("Time", metric.timestamp.timeIntervalSince(viewModel.startTime)),
                        y: .value("Cadence", cadence),
                        series: .value("Metric", "Cadence")
                    )
                    .foregroundStyle(.blue)
                }
                
                if let speed = metric.speed, speed != 0 {
                    LineMark(
                        x: .value("Time", metric.timestamp.timeIntervalSince(viewModel.startTime)),
                        y: .value("Speed", speed),
                        series: .value("Metric", "Speed")
                    )
                    .foregroundStyle(.green)
                }
                
                if let power = metric.power, power != 0 {
                    LineMark(
                        x: .value("Time", metric.timestamp.timeIntervalSince(viewModel.startTime)),
                        y: .value("Power", power),
                        series: .value("Metric", "Power")
                    )
                    .foregroundStyle(.purple)
                }
                
                if let resistance = metric.resistance, resistance != 0 {
                    LineMark(
                        x: .value("Time", metric.timestamp.timeIntervalSince(viewModel.startTime)),
                        y: .value("Resistance", resistance),
                        series: .value("Metric", "Resistance")
                    )
                    .foregroundStyle(.orange)
                }
                
                // Average lines
                if averages.cadence > 0 {
                    RuleMark(
                        y: .value("Avg Cadence", averages.cadence)
                    )
                    .foregroundStyle(.blue.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .trailing) {
                        Text("Avg: \(Int(averages.cadence))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if averages.speed > 0 {
                    RuleMark(
                        y: .value("Avg Speed", averages.speed)
                    )
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .trailing) {
                        Text("Avg: \(averages.speed, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                if averages.power > 0 {
                    RuleMark(
                        y: .value("Avg Power", averages.power)
                    )
                    .foregroundStyle(.purple.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .trailing) {
                        Text("Avg: \(Int(averages.power))")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
                
                if averages.resistance > 0 {
                    RuleMark(
                        y: .value("Avg Resistance", averages.resistance)
                    )
                    .foregroundStyle(.purple.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .trailing) {
                        Text("Avg: \(Int(averages.resistance))")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
            .frame(height: 300)
            .chartForegroundStyleScale([
                "Cadence": .blue,
                "Speed": .green,
                "Power": .purple,
                "Resistance": .orange
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: 10)) { value in // Stride by 60 seconds (1 minute)
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let seconds = value.as(Double.self) {
                            Text(elapsedTimeString(from: seconds))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine() // Adds grid lines
                    AxisTick() // Adds small tick marks
                    AxisValueLabel() // Adds labels
                }
            }
            .chartLegend(position: .bottom, alignment: .center, spacing: 8)
        }
        .onAppear(perform: startAverageCalculation)
    }
    
    // Helper to format elapsed time
      private func elapsedTimeString(from seconds: Double) -> String {
          let totalSeconds = Int(seconds)
          let hours = totalSeconds / 3600
          let minutes = (totalSeconds % 3600) / 60
          let remainingSeconds = totalSeconds % 60
          return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
      }
    
    // Start the timer to calculate averages every 5 seconds
      private func startAverageCalculation() {
          Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
              calculateRealAverages()
          }
      }

      // Calculate averages based on historical metrics
      private func calculateRealAverages() {
          let metrics = viewModel.historicalMetrics
          guard !metrics.isEmpty else { return }

          let totalCadence = metrics.compactMap { $0.cadence }.reduce(0, +)
          let totalSpeed = metrics.compactMap { $0.speed }.reduce(0, +)
          let totalPower = metrics.compactMap { $0.power }.reduce(0, +)
          let totalResistance = metrics.compactMap { $0.resistance }.reduce(0, +)

          let countCadence = metrics.compactMap { $0.cadence }.count
          let countSpeed = metrics.compactMap { $0.speed }.count
          let countPower = metrics.compactMap { $0.power }.count
          let countResistance = metrics.compactMap { $0.resistance }.count

          DispatchQueue.main.async {
              averages = Averages(
                  cadence: countCadence > 0 ? totalCadence / countCadence : 0,
                  speed: countSpeed > 0 ? totalSpeed / countSpeed : 0,
                  power: countPower > 0 ? totalPower / countPower : 0,
                  resistance: countResistance > 0 ? totalResistance / countResistance : 0
              )
          }
      }
}

struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(text)
                .font(.caption)
        }
    }
}
