//
//  ToastView.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import SwiftUI

struct ToastView: View {
    let value: Int
    
    var body: some View {
        Text("New streak! 🎉 - \(value.formatted())")
            .contentTransition(.numericText(value: Double(value)))
            .animation(.default, value: value)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [.pink, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .pink.opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ToastView(value: 18)
}
