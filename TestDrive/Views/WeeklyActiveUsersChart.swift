import SwiftUI
import Charts

struct WeeklyActiveUsersChart: View {
    let data: [WeeklyActiveUsersData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Active Users Distribution by iOS Version")
                .font(.headline)
                .padding(.bottom, 5)
            
            if data.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(height: 300)
            } else {
                Chart(data) { item in
                    LineMark(
                        x: .value("Week", item.week),
                        y: .value("Share %", item.shareAsPercentage),
                        series: .value("iOS Version", item.displayVersion)
                    )
                    .foregroundStyle(by: .value("iOS Version", item.displayVersion))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .frame(height: 350)
                .chartYAxis {
                    AxisMarks(values: .stride(by: 10)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))%")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading, spacing: 10)
                
                // Summary of latest week
                if let latestWeekSummary = calculateLatestWeekSummary() {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Latest Week Summary:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        ForEach(latestWeekSummary.prefix(5), id: \.iosVersion) { item in
                            HStack {
                                Text(item.displayVersion)
                                    .font(.caption)
                                Spacer()
                                Text("\(String(format: "%.1f%%", item.shareAsPercentage))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func calculateLatestWeekSummary() -> [WeeklyActiveUsersData]? {
        guard !data.isEmpty else { return nil }
        
        // Find the latest week
        guard let latestWeek = data.map({ $0.week }).max() else { return nil }
        
        // Get all data for the latest week and sort by share percentage
        let latestWeekData = data
            .filter { $0.week == latestWeek }
            .sorted { $0.shareOfUsers > $1.shareOfUsers }
        
        return latestWeekData.isEmpty ? nil : latestWeekData
    }
}