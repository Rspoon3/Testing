import Dependencies
import SwiftUI

@main
struct TestDriveApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = EncryptionSession()

    init() {
        prepareDependencies {
            try! $0.bootstrapDatabase()
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                session.lock()
            }
        }
    }
}
