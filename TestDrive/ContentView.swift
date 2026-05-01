import SwiftUI

struct ContentView: View {
    @State private var store = TranscriptionStore()
    @State private var showingNewTranscription = false
    @State private var isAvailable = false

    var body: some View {
        NavigationView {
            Group {
                if isAvailable {
                    transcriptionGridView
                } else {
                    ContentUnavailableView(
                        "Speech Recognition Not Available",
                        systemImage: "mic.slash",
                        description: Text("This device doesn't support the advanced speech recognition features required for this app.")
                    )
                }
            }
            .navigationTitle("Voice Journal")
            .toolbar {
                if isAvailable {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingNewTranscription = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewTranscription) {
                NewTranscriptionView(store: store)
            }
            .task {
                isAvailable = await store.isAvailable()
            }
        }
    }

    private var transcriptionGridView: some View {
        Group {
            if store.transcriptions.isEmpty {
                ContentUnavailableView(
                    "No Transcriptions Yet",
                    systemImage: "mic.badge.plus",
                    description: Text("Tap the plus button to create your first voice transcription.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150), spacing: 12)
                    ], spacing: 12) {
                        ForEach(store.transcriptions) { entry in
                            TranscriptionCardView(entry: entry, store: store)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}