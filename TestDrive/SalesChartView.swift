//
//  SalesChartView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/8/25.
//

import SwiftUI
import Charts

struct SalesData: Identifiable {
    let id = UUID()
    let day: String
    let sales: Double
    let city: String
}

struct SalesChartView: View {
    let salesData = [
        SalesData(day: "Mon", sales: 916, city: "London"),
        SalesData(day: "Tue", sales: 798, city: "London"),
        SalesData(day: "Wed", sales: 663, city: "London"),
        SalesData(day: "Thu", sales: 890, city: "London"),
        SalesData(day: "Fri", sales: 1200, city: "London"),
        
        SalesData(day: "Mon", sales: 502, city: "Berlin"),
        SalesData(day: "Tue", sales: 670, city: "Berlin"),
        SalesData(day: "Wed", sales: 420, city: "Berlin"),
        SalesData(day: "Thu", sales: 580, city: "Berlin"),
        SalesData(day: "Fri", sales: 750, city: "Berlin"),
    ]
    
    var body: some View {
        VStack {
            Text("Sales by City")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom)
            
            Chart(salesData) { data in
                BarMark(
                    x: .value("Day", data.day),
                    y: .value("Sales", data.sales)
                )
                .foregroundStyle(by: .value("City", data.city))
            }
            .frame(height: 300)
            .border(Color.red, width: 1)
        }
    }
}

#Preview {
    SalesChartView()
}
