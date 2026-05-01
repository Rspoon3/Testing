import SwiftUI
import Charts

struct IOSVersionChart: View {
    let data: [IOSVersionData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("iOS Version Distribution")
                .font(.headline)
                .padding(.bottom, 5)
            
            Chart(data, id: \.iosVersion) { item in
                BarMark(
                    x: .value("iOS Version", item.iosVersion),
                    y: .value("Active Users", item.countOfActiveUsers)
                )
                .foregroundStyle(.blue)
            }
            .frame(height: 250)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}