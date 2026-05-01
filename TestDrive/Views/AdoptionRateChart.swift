import SwiftUI
import Charts

struct AdoptionRateChart: View {
    let data: [AdoptionRateData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Version Adoption Rate")
                .font(.headline)
                .padding(.bottom, 5)
            
            let latestRates = calculateLatestRates()
            
            // Display as a bar chart showing current adoption rates
            Chart(latestRates, id: \.version) { item in
                BarMark(
                    x: .value("Adoption %", item.rate),
                    y: .value("Version", item.version)
                )
                .foregroundStyle(.green)
                .annotation(position: .trailing) {
                    Text(String(format: "%.3f%%", item.rate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 300)
            
            // Also show summary text
            if let topVersion = latestRates.first {
                Text("Top version: \(topVersion.version) at \(String(format: "%.3f%%", topVersion.rate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func calculateLatestRates() -> [(version: String, rate: Double)] {
        // Get the latest adoption rate for each version
        let groupedData = Dictionary(grouping: data) { $0.version }
        return groupedData.compactMap { (version, data) -> (version: String, rate: Double)? in
            guard let latest = data.max(by: { $0.timestamp < $1.timestamp }) else { return nil }
            return (version: version, rate: latest.adoptionRate)
        }
        .sorted { $0.rate > $1.rate }
        .prefix(10) // Show top 10 versions
        .map { $0 }
    }
}