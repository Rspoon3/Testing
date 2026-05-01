import SwiftUI
import SwiftData
import ClocksyKit

@main
struct TestDriveApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TimerFolder.self,
            TimerItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
