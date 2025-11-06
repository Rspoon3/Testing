//
//  TestDriveApp.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI
import SwiftData

@main
struct TestDriveApp: App {
    @State private var modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: DownloadedEpisode.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            let modelContext = modelContainer.mainContext
            let apiService = PodcastAPIService()
            let downloadManager = DownloadManager(modelContext: modelContext)
            let playbackManager = PlaybackManager(modelContext: modelContext)
            let viewModel = EpisodesListViewModel(
                apiService: apiService,
                downloadManager: downloadManager,
                playbackManager: playbackManager,
                modelContext: modelContext
            )

            EpisodesListView(viewModel: viewModel)
        }
        .modelContainer(modelContainer)
    }
}
