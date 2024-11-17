//
//  SwipePercentageView.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import SwiftUI

struct SwipePercentageView: View {
    @AppStorage("totalSwipes") private var totalSwipes = 0
    @AppStorage("correctSwipes") private var correctSwipes = 0

    private var correctPercentage: Double {
        guard totalSwipes > 0 else { return 0.0 }
        return (Double(correctSwipes) / Double(totalSwipes))
    }
    
    var body: some View {
        Text(correctPercentage.formatted(.percent.precision(.fractionLength(1))))
            .contentTransition(.numericText(value: correctPercentage))
            .font(.system(size: 60, weight: .bold, design: .rounded))
            .animation(.default, value: correctPercentage)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.teal, Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

#Preview {
    SwipePercentageView()
}
