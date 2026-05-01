import SwiftUI
import SwiftData

struct AddTimerSheet: View {
    @Bindable var folder: TimerFolder
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    
    @State private var timerName = ""
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var selectedColor = Color(hex: "#D4A373")
    @State private var selectedSound = TimerSound.gentle
    
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
                            
                            TextField("e.g. Take a shower, Read emails", text: $timerName)
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
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Color(hex: "#8B7355"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTimer()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#D4A373"))
                    .disabled(timerName.isEmpty || (minutes == 0 && seconds == 0))
                }
            }
        }
    }
    
    private func saveTimer() {
        let duration = TimeInterval(minutes * 60 + seconds)
        let newTimer = TimerItem(
            name: timerName,
            duration: duration,
            colorHex: selectedColor.toHex(),
            soundName: selectedSound.rawValue
        )
        newTimer.sortOrder = folder.timers.count
        folder.timers.append(newTimer)
        
        try? modelContext.save()
        isPresented = false
    }
}