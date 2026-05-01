import SwiftUI
import Charts

struct SwiftSLOCChart: View {
    let data: [SwiftSLOCData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Swift Lines of Code")
                .font(.headline)
                .padding(.bottom, 5)
            
            Chart(data) { item in
                LineMark(
                    x: .value("Date", item.timestamp),
                    y: .value("Lines", item.linesOfCode)
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .frame(height: 250)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}