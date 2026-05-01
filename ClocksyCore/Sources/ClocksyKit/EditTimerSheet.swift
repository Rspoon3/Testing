import SwiftUI
import SwiftData

struct EditTimerSheet: View {
    @Bindable var timer: TimerItem
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    let onDismiss: () -> Void
    
    @State private var timerName: String
    @State private var minutes: Int
    @State private var seconds: Int
    @State private var selectedColor: Color
    @State private var selectedSound: TimerSound
    
    init(timer: TimerItem, isPresented: Binding<Bool>, onDismiss: @escaping () -> Void) {
        self.timer = timer
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        
        let totalSeconds = Int(timer.duration)
        self._timerName = State(initialValue: timer.name)
        self._minutes = State(initialValue: totalSeconds / 60)
        self._seconds = State(initialValue: totalSeconds % 60)
        self._selectedColor = State(initialValue: Color(hex: timer.colorHex))
        self._selectedSound = State(initialValue: TimerSound(rawValue: timer.soundName) ?? .gentle)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#FFF5E6"),
                        Color(hex: "#FFE8D6")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Timer Name")
                                .font(.custom("Avenir Next", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "#8B7355"))
                            
                            TextField("Timer name", text: $timerName)
                                .font(.custom("Avenir Next", size: 18))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.8))
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.custom("Avenir Next", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "#8B7355"))
                            
                            HStack(spacing: 20) {
                                VStack {
                                    Picker("Minutes", selection: $minutes) {
                                        ForEach(0..<60) { min in
                                            Text("\(min)").tag(min)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 80, height: 120)
                                    
                                    Text("minutes")
                                        .font(.custom("Avenir Next", size: 14))
                                        .foregroundColor(Color(hex: "#A0896C"))
                                }
                                
                                VStack {
                                    Picker("Seconds", selection: $seconds) {
                                        ForEach(0..<60) { sec in
                                            Text("\(sec)").tag(sec)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 80, height: 120)
                                    
                                    Text("seconds")
                                        .font(.custom("Avenir Next", size: 14))
                                        .foregroundColor(Color(hex: "#A0896C"))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.5))
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Timer Color")
                                .font(.custom("Avenir Next", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "#8B7355"))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(ThemeColors.allColors, id: \.self) { color in
                                        Circle()
                                            .fill(color)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedColor == color ? Color(hex: "#5C4033") : Color.clear, lineWidth: 3)
                                            )
                                            .onTapGesture {
                                                selectedColor = color
                                            }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Alert Sound")
                                .font(.custom("Avenir Next", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "#8B7355"))
                            
                            VStack(spacing: 8) {
                                ForEach(TimerSound.allCases, id: \.self) { sound in
                                    HStack {
                                        Text(sound.rawValue)
                                            .font(.custom("Avenir Next", size: 16))
                                            .foregroundColor(Color(hex: "#5C4033"))
                                        
                                        Spacer()
                                        
                                        if selectedSound == sound {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(hex: "#D4A373"))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedSound == sound ? Color.white.opacity(0.8) : Color.white.opacity(0.3))
                                    )
                                    .onTapGesture {
                                        selectedSound = sound
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(Color(hex: "#8B7355"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#D4A373"))
                    .disabled(timerName.isEmpty || (minutes == 0 && seconds == 0))
                }
            }
        }
    }
    
    private func saveChanges() {
        timer.name = timerName
        timer.duration = TimeInterval(minutes * 60 + seconds)
        timer.colorHex = selectedColor.toHex()
        timer.soundName = selectedSound.rawValue
        
        try? modelContext.save()
        onDismiss()
    }
}