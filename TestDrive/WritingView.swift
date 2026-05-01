import SwiftUI
import Combine

struct WritingView: View {
    @State private var text: String = ""
    @State private var timeRemaining: Double = 30.0
    @State private var isDeleting: Bool = false
    @State private var deletionTimer: Timer?
    @State private var countdownTimer: Timer?
    @State private var lastTextCount: Int = 0
    @State private var debounceTimer: Timer?
    @State private var showSettings: Bool = false

    @AppStorage("maxTime") private var maxTime: Double = 30.0
    @AppStorage("debounceDelay") private var debounceDelay: Double = 10.0
    @AppStorage("deletionSpeed") private var deletionSpeed: Double = 1.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TextEditor(text: $text)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .font(.system(size: 17))
                    .onChange(of: text) { _, newValue in
                        handleTextChange(newValue)
                    }
            }
            .navigationTitle("Text Timeout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    CircularProgressView(progress: timeRemaining / maxTime)
                        .frame(width: 28, height: 28)
                    
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: text) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                startCountdown()
            }
            .onDisappear {
                stopAllTimers()
            }
        }
    }
    
    private func handleTextChange(_ newValue: String) {
        let currentCount = newValue.count

        if currentCount > lastTextCount {
            let charactersAdded = currentCount - lastTextCount
            stopDeletion()

            timeRemaining = min(timeRemaining + (Double(charactersAdded) * 0.5), maxTime)
        }

        lastTextCount = currentCount

        stopCountdown()
        startDebounceTimer()
    }

    private func startDebounceTimer() {
        debounceTimer?.invalidate()

        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { _ in
            if !text.isEmpty {
                startCountdown()
            }
        }
    }

    private func stopDebounceTimer() {
        debounceTimer?.invalidate()
        debounceTimer = nil
    }
    
    private func startCountdown() {
        stopCountdown()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if !text.isEmpty {
                if timeRemaining > 0 {
                    timeRemaining -= 0.1
                } else {
                    timeRemaining = 0
                    startDeletion()
                }
            }
        }
    }
    
    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func startDeletion() {
        guard !isDeleting && !text.isEmpty else { return }
        
        stopCountdown()
        isDeleting = true
        deletionSpeed = deletionSpeed
        
        scheduleNextDeletion()
    }
    
    private func scheduleNextDeletion() {
        guard isDeleting else { return }
        
        deletionTimer?.invalidate()
        
        let delay = 1.0 / deletionSpeed
        
        deletionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            if !self.text.isEmpty && self.isDeleting {
                self.text.removeLast()
                self.lastTextCount = self.text.count
                
                self.deletionSpeed = min(self.deletionSpeed * 1.15, 20.0)
                
                if !self.text.isEmpty {
                    self.scheduleNextDeletion()
                } else {
                    self.stopDeletion()
                }
            }
        }
    }
    
    private func stopDeletion() {
        isDeleting = false
        deletionTimer?.invalidate()
        deletionTimer = nil
        deletionSpeed = deletionSpeed
    }
    
    private func stopAllTimers() {
        stopCountdown()
        stopDeletion()
        stopDebounceTimer()
    }
}

#Preview {
    WritingView()
}
