import SwiftUI
import SwiftData

struct FolderDetailView: View {
    @Bindable var folder: TimerFolder
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddTimer = false
    @State private var editingTimer: TimerItem?
    
    var body: some View {
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
                VStack(spacing: 16) {
                    if folder.timers.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "timer")
                                .font(.system(size: 60))
                                .foregroundColor(Color(hex: folder.colorHex))
                            
                            Text("No timers yet")
                                .font(.custom("Avenir Next", size: 24))
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "#8B7355"))
                            
                            Text("Add your first timer to start timeboxing")
                                .font(.custom("Avenir Next", size: 16))
                                .foregroundColor(Color(hex: "#A0896C"))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(folder.timers.sorted(by: { $0.sortOrder < $1.sortOrder })) { timer in
                            NavigationLink(destination: TimerRunningView(timer: timer, folderName: folder.name)) {
                                TimerCardView(timer: timer)
                            }
                            .contextMenu {
                                Button {
                                    toggleFavorite(timer)
                                } label: {
                                    Label(timer.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                          systemImage: timer.isFavorite ? "star.slash" : "star")
                                }
                                
                                Button {
                                    editingTimer = timer
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    deleteTimer(timer)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 80)
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddTimer = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: folder.colorHex))
                }
            }
        }
        .sheet(isPresented: $showingAddTimer) {
            AddTimerSheet(folder: folder, isPresented: $showingAddTimer)
        }
        .sheet(item: $editingTimer) { timer in
            EditTimerSheet(timer: timer, isPresented: .constant(true)) {
                editingTimer = nil
            }
        }
    }
    
    private func deleteTimer(_ timer: TimerItem) {
        if let index = folder.timers.firstIndex(where: { $0.id == timer.id }) {
            folder.timers.remove(at: index)
            try? modelContext.save()
        }
    }
    
    private func toggleFavorite(_ timer: TimerItem) {
        timer.isFavorite.toggle()
        try? modelContext.save()
    }
}

struct TimerCardView: View {
    let timer: TimerItem
    
    var formattedDuration: String {
        let minutes = Int(timer.duration) / 60
        let seconds = Int(timer.duration) % 60
        if seconds == 0 {
            return "\(minutes) min"
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(timer.name)
                        .font(.custom("Avenir Next", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#5C4033"))
                    
                    if timer.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#F4A460"))
                    }
                }
                
                HStack(spacing: 12) {
                    Label(formattedDuration, systemImage: "timer")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundColor(Color(hex: "#A0896C"))
                    
                    Label(timer.soundName, systemImage: "speaker.wave.2")
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundColor(Color(hex: "#A0896C"))
                }
            }
            
            Spacer()
            
            Circle()
                .fill(Color(hex: timer.colorHex))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color(hex: timer.colorHex).opacity(0.15), radius: 4, x: 0, y: 2)
        )
    }
}