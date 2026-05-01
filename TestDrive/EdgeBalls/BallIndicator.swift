//
//  BallIndicator.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 8/20/25.
//

import SwiftUI

struct BallIndicator: View {
    let rect: CGRect
    let date: Date
    let timeUnit: TimeUnit
    let cornerRadius: CGFloat = 50
    private let pathHelper: RoundedRectanglePath
    
    // MARK: - Initializer
    
    init(rect: CGRect, date: Date, timeUnit: TimeUnit) {
        self.rect = rect
        self.date = date
        self.timeUnit = timeUnit
        self.pathHelper = RoundedRectanglePath(rect: rect, cornerRadius: cornerRadius)
    }
    
    var ballPosition: CGPoint {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        let nanosecond = calendar.component(.nanosecond, from: date)
        
        let fraction: Double
        
        switch timeUnit {
        case .hours:
            // Hours ball completes a full cycle in 12 hours
            let minuteFraction = Double(minute) / 60.0
            let secondFraction = Double(second) / 3600.0
            fraction = (Double(hour % 12) + minuteFraction + secondFraction) / 12.0
        case .minutes:
            // Minutes ball completes a full cycle in 60 minutes
            let secondFraction = Double(second) / 60.0
            let nanoFraction = Double(nanosecond) / (60.0 * 1_000_000_000)
            fraction = (Double(minute) + secondFraction + nanoFraction) / 60.0
        case .seconds:
            // Seconds ball completes a full cycle in 60 seconds
            let nanoFraction = Double(nanosecond) / 1_000_000_000
            fraction = (Double(second) + nanoFraction) / 60.0
        case .milliseconds:
            // Milliseconds ball completes a full cycle in 1000 milliseconds (1 second)
            let millisecond = Double(nanosecond) / 1_000_000
            fraction = millisecond / 1000.0
        }
        
        return pathHelper.timePosition(for: fraction)
    }
    
    private var ballSize: CGFloat {
        switch timeUnit {
        case .hours: return 30
        case .minutes: return 20
        case .seconds: return 12
        case .milliseconds: return 8
        }
    }
    
    private var ballColor: Color {
        switch timeUnit {
        case .hours: return .orange
        case .minutes: return .blue
        case .seconds: return .green
        case .milliseconds: return .purple
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Circle()
            .fill(ballColor.gradient)
            .frame(width: ballSize, height: ballSize)
            .shadow(color: ballColor.opacity(0.5), radius: 5)
            .position(ballPosition)
    }
}
