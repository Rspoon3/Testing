import SwiftUI

struct CircularRingsClockView: View {
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
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Digital time display
                    Text(timeline.date.formatted(date: .omitted, time: .complete))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    // Concentric rings like Apple Watch
                    ZStack {
                        // Hours ring (outermost)
                        TimeCircularRing(
                            timeUnit: .hours,
                            date: timeline.date,
                            color: .orange,
                            ringWidth: 16,
                            radius: 120
                        )
                        
                        // Minutes ring
                        TimeCircularRing(
                            timeUnit: .minutes,
                            date: timeline.date,
                            color: .blue,
                            ringWidth: 14,
                            radius: 90
                        )
                        
                        // Seconds ring
                        TimeCircularRing(
                            timeUnit: .seconds,
                            date: timeline.date,
                            color: .green,
                            ringWidth: 12,
                            radius: 60
                        )
                        
                        // Milliseconds ring (innermost, if enabled)
                        if showMilliseconds {
                            TimeCircularRing(
                                timeUnit: .milliseconds,
                                date: timeline.date,
                                color: .purple,
                                ringWidth: 10,
                                radius: 30
                            )
                        }
                    }
                    
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
    CircularRingsClockView(showMilliseconds: true)
}