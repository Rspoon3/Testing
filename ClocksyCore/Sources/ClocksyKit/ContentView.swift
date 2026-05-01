import SwiftUI
import SwiftData

public struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimerFolder.sortOrder) private var folders: [TimerFolder]
    @Query(filter: #Predicate<TimerItem> { $0.isFavorite }) private var favoriteTimers: [TimerItem]
    @State private var showingAddFolder = false
    @State private var newFolderName = ""
    @State private var selectedColor = Color(hex: "#E8B4A5")
    @State private var editingFolder: TimerFolder?
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public
    
    public var body: some View {
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
                    VStack(spacing: 20) {
                        // Favorites Section
                        if !favoriteTimers.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(Color(hex: "#F4A460"))
                                    Text("Favorites")
                                        .font(.custom("Avenir Next", size: 20))
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "#5C4033"))
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(favoriteTimers) { timer in
                                            NavigationLink(destination: TimerRunningView(
                                                timer: timer,
                                                folderName: timer.folder?.name ?? "Favorites"
                                            )) {
                                                FavoriteTimerCard(timer: timer)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 20)
                        }
                        
                        // Folders Section
                        if folders.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color(hex: "#D4A373"))
                                
                                Text("No folders yet")
                                    .font(.custom("Avenir Next", size: 24))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: "#8B7355"))
                                
                                Text("Create your first folder to organize your timers")
                                    .font(.custom("Avenir Next", size: 16))
                                    .foregroundColor(Color(hex: "#A0896C"))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, favoriteTimers.isEmpty ? 100 : 40)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                if !favoriteTimers.isEmpty {
                                    Text("Folders")
                                        .font(.custom("Avenir Next", size: 20))
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "#5C4033"))
                                        .padding(.horizontal)
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    ForEach(folders) { folder in
                                        NavigationLink(destination: FolderDetailView(folder: folder)) {
                                            FolderCardView(folder: folder)
                                        }
                                        .contextMenu {
                                            Button {
                                                editingFolder = folder
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            
                                            Button(role: .destructive) {
                                                deleteFolder(folder)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, favoriteTimers.isEmpty ? 20 : 0)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Timebox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFolder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#D4A373"))
                    }
                }
            }
            .sheet(isPresented: $showingAddFolder) {
                AddFolderSheet(
                    isPresented: $showingAddFolder,
                    folderName: $newFolderName,
                    selectedColor: $selectedColor
                ) {
                    addFolder()
                }
            }
            .sheet(item: $editingFolder) { folder in
                EditFolderSheet(folder: folder, isPresented: .constant(true)) {
                    editingFolder = nil
                }
            }
        }
    }
    
    private func addFolder() {
        let newFolder = TimerFolder(
            name: newFolderName,
            colorHex: selectedColor.toHex(),
            sortOrder: folders.count
        )
        modelContext.insert(newFolder)
        newFolderName = ""
        selectedColor = Color(hex: "#E8B4A5")
    }
    
    private func deleteFolder(_ folder: TimerFolder) {
        modelContext.delete(folder)
        try? modelContext.save()
    }
}

struct FavoriteTimerCard: View {
    let timer: TimerItem
    
    var formattedDuration: String {
        let minutes = Int(timer.duration) / 60
        let seconds = Int(timer.duration) % 60
        if seconds == 0 {
            return "\(minutes)m"
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(hex: timer.colorHex))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "timer")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )
            
            Text(timer.name)
                .font(.custom("Avenir Next", size: 14))
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "#5C4033"))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
            
            Text(formattedDuration)
                .font(.custom("Avenir Next", size: 12))
                .foregroundColor(Color(hex: "#A0896C"))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color(hex: timer.colorHex).opacity(0.15), radius: 4, x: 0, y: 2)
        )
    }
}

struct FolderCardView: View {
    let folder: TimerFolder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: folder.colorHex))
                
                Spacer()
                
                Text("\(folder.timers.count)")
                    .font(.custom("Avenir Next", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#8B7355"))
            }
            
            Text(folder.name)
                .font(.custom("Avenir Next", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "#5C4033"))
                .lineLimit(2)
            
            Text("\(folder.timers.count) timer\(folder.timers.count == 1 ? "" : "s")")
                .font(.custom("Avenir Next", size: 14))
                .foregroundColor(Color(hex: "#A0896C"))
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color(hex: folder.colorHex).opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TimerFolder.self, inMemory: true)
}

#Preview("Folder Card") {
    let folder = TimerFolder(name: "Morning Routine", colorHex: "#E8B4A5")
    folder.timers = [
        TimerItem(name: "Shower", duration: 600, colorHex: "#D4A373"),
        TimerItem(name: "Breakfast", duration: 900, colorHex: "#FFB6A3"),
        TimerItem(name: "Get Dressed", duration: 300, colorHex: "#FFC4A3")
    ]
    
    return FolderCardView(folder: folder)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#FFF5E6"),
                    Color(hex: "#FFE8D6")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .modelContainer(for: TimerFolder.self, inMemory: true)
}
