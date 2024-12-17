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
                .padding()
            
            Text(value)
                .font(.largeTitle)
                .foregroundColor(.blue)
                
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fit) // Ensures a square shape
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
