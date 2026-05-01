import SwiftUI

struct ContentView: View {
    @AppStorage("showMilliseconds") private var showMilliseconds = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Settings") {
                    Toggle("Show Milliseconds", isOn: $showMilliseconds)
                        .tint(.purple)
                }
                
                Section("Clock Faces") {
                    NavigationLink(destination: RectangularClockView(showMilliseconds: showMilliseconds)) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Rectangular Path Clock")
                                    .font(.headline)
                                Text("Balls travel along a rounded rectangle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    NavigationLink(destination: PhysicsBallClockView(showMilliseconds: showMilliseconds)) {
                        HStack {
                            Image(systemName: "circles.hexagonpath")
                                .foregroundColor(.green)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Physics Ball Clock")
                                    .font(.headline)
                                Text("Balls drop and respond to device motion")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    NavigationLink(destination: ProgressBarClockView(showMilliseconds: showMilliseconds)) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.purple)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Progress Bar Clock")
                                    .font(.headline)
                                Text("Horizontal progress bars show time flow")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    NavigationLink(destination: CircularRingsClockView(showMilliseconds: showMilliseconds)) {
                        HStack {
                            Image(systemName: "circle.hexagongrid")
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text("Circular Rings Clock")
                                    .font(.headline)
                                Text("Concentric rings like Apple Watch")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Features") {
                    Label("Hours in orange", systemImage: "circle.fill")
                        .foregroundColor(.orange)
                    Label("Minutes in blue", systemImage: "circle.fill")
                        .foregroundColor(.blue)
                    Label("Seconds in green", systemImage: "circle.fill")
                        .foregroundColor(.green)
                    if showMilliseconds {
                        Label("Milliseconds in purple", systemImage: "circle.fill")
                            .foregroundColor(.purple)
                    }
                }
                .font(.footnote)
            }
            .navigationTitle("Watch Faces")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ContentView()
}