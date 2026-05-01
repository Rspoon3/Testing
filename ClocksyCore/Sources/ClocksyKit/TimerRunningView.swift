import SwiftUI
import AVFoundation

struct TimerRunningView: View {
    let timer: TimerItem
    let folderName: String
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: TimeInterval
    @State private var isRunning = false
    @State private var timerCancellable: Timer?
    @State private var progress: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var soundTimer: Timer?
    @State private var isAlerting = false
    
    init(timer: TimerItem, folderName: String) {
        self.timer = timer
        self.folderName = folderName
        self._timeRemaining = State(initialValue: timer.duration)
    }
    
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var encouragingMessage: String {
        let percentage = 1.0 - (timeRemaining / timer.duration)
        switch percentage {
        case 0..<0.25:
            return "You've got this!"
        case 0.25..<0.5:
            return "Keep going, you're doing great!"
        case 0.5..<0.75:
            return "Halfway there! Stay focused!"
        case 0.75..<0.95:
            return "Almost done! Final stretch!"
        case 0.95...1:
            return "Fantastic work!"
        default:
            return "Stay mindful of your time"
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: timer.colorHex).opacity(0.3),
                    Color(hex: "#FFE8D6")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Text(timer.name)
                        .font(.custom("Avenir Next", size: 28))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#5C4033"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(encouragingMessage)
                        .font(.custom("Avenir Next", size: 16))
                        .foregroundColor(Color(hex: "#8B7355"))
                        .opacity(isRunning ? 1 : 0.6)
                        .animation(.easeInOut(duration: 0.3), value: isRunning)
                }
                
                ZStack {
                    Circle()
                        .stroke(Color(hex: timer.colorHex).opacity(0.2), lineWidth: 20)
                        .frame(width: 260, height: 260)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color(hex: timer.colorHex),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 260, height: 260)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)
                    
                    VStack(spacing: 8) {
                        Text(formattedTime)
                            .font(.custom("Avenir Next", size: 56))
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "#5C4033"))
                            .monospacedDigit()
                        
                        Text(isAlerting ? "COMPLETE" : isRunning ? "RUNNING" : timeRemaining == timer.duration ? "READY" : "PAUSED")
                            .font(.custom("Avenir Next", size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(isAlerting ? .red : Color(hex: timer.colorHex))
                            .tracking(2)
                    }
                }
                
                HStack(spacing: 30) {
                    Button {
                        resetTimer()
                    } label: {
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: "#8B7355"))
                            )
                            .shadow(color: Color(hex: "#8B7355").opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    Button {
                        if isRunning {
                            pauseTimer()
                        } else {
                            startTimer()
                        }
                    } label: {
                        Circle()
                            .fill(Color(hex: timer.colorHex))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                    .offset(x: isRunning ? 0 : 3)
                            )
                            .shadow(color: Color(hex: timer.colorHex).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button {
                        stopTimer()
                        dismiss()
                    } label: {
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: "#8B7355"))
                            )
                            .shadow(color: Color(hex: "#8B7355").opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    stopTimer()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(folderName)
                    }
                    .foregroundColor(Color(hex: "#8B7355"))
                }
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        if isAlerting {
            stopAlarm()
            resetTimer()
        }
        isRunning = true
        timerCancellable = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 0.1
                progress = 1.0 - (timeRemaining / timer.duration)
                
                if timeRemaining <= 0 {
                    timeRemaining = 0
                    progress = 1.0
                    timerComplete()
                }
            }
        }
    }
    
    private func pauseTimer() {
        if isAlerting {
            stopAlarm()
        } else {
            isRunning = false
            timerCancellable?.invalidate()
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timerCancellable?.invalidate()
        stopAlarm()
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = timer.duration
        progress = 0
        isAlerting = false
    }
    
    private func timerComplete() {
        isRunning = false
        timerCancellable?.invalidate()
        isAlerting = true
        startAlarm()
    }
    
    private func startAlarm() {
        playSound()
        soundTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            playSound()
        }
    }
    
    private func stopAlarm() {
        isAlerting = false
        soundTimer?.invalidate()
        soundTimer = nil
    }
    
    private func playSound() {
        AudioServicesPlaySystemSound(SystemSoundID(1304))
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}