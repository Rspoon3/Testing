//
//  MetricTile.swift
//  Testing
//
//  Created by Ricky on 12/17/24.
//

import SwiftUI

struct MetricTile: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack {
            Text(label)
                .font(.headline)
            Text(value)
                .font(.largeTitle)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    MetricTile(
        label: "Distance",
        value: "1.17"
    )
}
