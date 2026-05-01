import SwiftUI

struct TimeProgressBar: View {
    let timeUnit: TimeUnit
    let date: Date
    let color: Color
    let label: String
    
    private var progress: Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        let nanosecond = calendar.component(.nanosecond, from: date)
        
        switch timeUnit {
        case .hours:
            // 12-hour cycle
            let currentHour = hour % 12
            let minuteFraction = Double(minute) / 60.0
            let secondFraction = Double(second) / 3600.0
            return (Double(currentHour) + minuteFraction + secondFraction) / 12.0
            
        case .minutes:
            // 60-minute cycle
            let secondFraction = Double(second) / 60.0
            let nanoFraction = Double(nanosecond) / (60.0 * 1_000_000_000)
            return (Double(minute) + secondFraction + nanoFraction) / 60.0
            
        case .seconds:
            // 60-second cycle
            let nanoFraction = Double(nanosecond) / 1_000_000_000
            return (Double(second) + nanoFraction) / 60.0
            
        case .milliseconds:
            // 100ms cycle (fills 10 times per second)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(currentValue) / \(maxValue)")
                    .font(.system(.title2, design: .monospaced))
                    .foregroundColor(color)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 12)
                        .cornerRadius(6)
                    
                    // Progress fill
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                        .cornerRadius(6)
                        .animation(timeUnit == .milliseconds ? .none : .linear(duration: 0.1), value: progress)
                    
                    // Glow effect
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 12)
                        .cornerRadius(6)
                        .blur(radius: 2)
                        .opacity(0.3)
                        .animation(timeUnit == .milliseconds ? .none : .linear(duration: 0.1), value: progress)
                }
            }
            .frame(height: 12)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TimeProgressBar(timeUnit: .hours, date: Date(), color: .orange, label: "Hours")
        TimeProgressBar(timeUnit: .minutes, date: Date(), color: .blue, label: "Minutes")
        TimeProgressBar(timeUnit: .seconds, date: Date(), color: .green, label: "Seconds")
        TimeProgressBar(timeUnit: .milliseconds, date: Date(), color: .purple, label: "Milliseconds")
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}