import SwiftUI

struct TimeCircularRing: View {
    let timeUnit: TimeUnit
    let date: Date
    let color: Color
    let ringWidth: CGFloat
    let radius: CGFloat
    
    private var progress: Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        let nanosecond = calendar.component(.nanosecond, from: date)
        
        switch timeUnit {
        case .hours:
            let currentHour = hour % 12
            let minuteFraction = Double(minute) / 60.0
            let secondFraction = Double(second) / 3600.0
            return (Double(currentHour) + minuteFraction + secondFraction) / 12.0
            
        case .minutes:
            let secondFraction = Double(second) / 60.0
            let nanoFraction = Double(nanosecond) / (60.0 * 1_000_000_000)
            return (Double(minute) + secondFraction + nanoFraction) / 60.0
            
        case .seconds:
            let nanoFraction = Double(nanosecond) / 1_000_000_000
            return (Double(second) + nanoFraction) / 60.0
            
        case .milliseconds:
            let timeInterval = date.timeIntervalSince1970
            let fractionalSeconds = timeInterval - floor(timeInterval)
            let progressIn100ms = (fractionalSeconds * 10).truncatingRemainder(dividingBy: 1.0)
            return progressIn100ms
        }
    }
    
    private var currentValue: String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        let nanosecond = calendar.component(.nanosecond, from: date)
        
        switch timeUnit {
        case .hours:
            let currentHour = hour % 12
            return currentHour == 0 ? "12" : "\(currentHour)"
        case .minutes:
            return "\(minute)"
        case .seconds:
            return "\(second)"
        case .milliseconds:
            let timeInterval = date.timeIntervalSince1970
            let fractionalSeconds = timeInterval - floor(timeInterval)
            let millisecond = Int(fractionalSeconds * 1000)
            return "\(millisecond)"
        }
    }
    
    private var maxValue: String {
        switch timeUnit {
        case .hours: return "12"
        case .minutes: return "60"
        case .seconds: return "60"
        case .milliseconds: return "1000"
        }
    }
    
    private var unitLabel: String {
        switch timeUnit {
        case .hours: return "H"
        case .minutes: return "M"
        case .seconds: return "S"
        case .milliseconds: return "ms"
        }
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: ringWidth)
                .frame(width: radius * 2, height: radius * 2)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.7), color],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: ringWidth,
                        lineCap: .round
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .animation(timeUnit == .milliseconds ? .none : .linear(duration: 0.1), value: progress)
            
            // Glow effect
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, lineWidth: ringWidth)
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(-90))
                .blur(radius: 3)
                .opacity(0.4)
                .animation(timeUnit == .milliseconds ? .none : .linear(duration: 0.1), value: progress)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            TimeCircularRing(timeUnit: .hours, date: Date(), color: .orange, ringWidth: 12, radius: 60)
            TimeCircularRing(timeUnit: .minutes, date: Date(), color: .blue, ringWidth: 10, radius: 50)
        }
        HStack(spacing: 20) {
            TimeCircularRing(timeUnit: .seconds, date: Date(), color: .green, ringWidth: 8, radius: 40)
            TimeCircularRing(timeUnit: .milliseconds, date: Date(), color: .purple, ringWidth: 6, radius: 30)
        }
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
