import SwiftUI

struct ProgressBarClockView: View {
    let showMilliseconds: Bool
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    init(showMilliseconds: Bool = false) {
        self.showMilliseconds = showMilliseconds
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: showMilliseconds ? 0.01 : 0.1)) { timeline in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Digital time display
                    Text(timeline.date.formatted(date: .omitted, time: .complete))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.bottom, 40)
                    
                    // Progress bars
                    VStack(spacing: 25) {
                        TimeProgressBar(
                            timeUnit: .hours,
                            date: timeline.date,
                            color: .orange,
                            label: "Hours"
                        )
                        
                        TimeProgressBar(
                            timeUnit: .minutes,
                            date: timeline.date,
                            color: .blue,
                            label: "Minutes"
                        )
                        
                        TimeProgressBar(
                            timeUnit: .seconds,
                            date: timeline.date,
                            color: .green,
                            label: "Seconds"
                        )
                        
                        if showMilliseconds {
                            TimeProgressBar(
                                timeUnit: .milliseconds,
                                date: timeline.date,
                                color: .purple,
                                label: "Milliseconds"
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Legend
                    VStack(spacing: 8) {
                        HStack {
                            Circle().fill(.orange).frame(width: 12, height: 12)
                            Text("Hours (12-hour cycle)")
                            Spacer()
                        }
                        HStack {
                            Circle().fill(.blue).frame(width: 12, height: 12)
                            Text("Minutes (60-minute cycle)")
                            Spacer()
                        }
                        HStack {
                            Circle().fill(.green).frame(width: 12, height: 12)
                            Text("Seconds (60-second cycle)")
                            Spacer()
                        }
                        if showMilliseconds {
                            HStack {
                                Circle().fill(.purple).frame(width: 12, height: 12)
                                Text("Milliseconds (100ms cycle - 10x/sec)")
                                Spacer()
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ProgressBarClockView(showMilliseconds: true)
}