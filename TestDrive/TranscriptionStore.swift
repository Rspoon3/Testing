import Foundation
import SwiftUI
import Speech

@Observable
class TranscriptionStore {
    private(set) var transcriptions: [TranscriptionEntry] = []
    private let saveKey = "SavedTranscriptions"

    init() {
        loadTranscriptions()
    }

    func addTranscription(_ entry: TranscriptionEntry) {
        transcriptions.append(entry)
        sortTranscriptions()
        saveTranscriptions()
    }

    func deleteTranscription(_ entry: TranscriptionEntry) {
        transcriptions.removeAll { $0.id == entry.id }
        saveTranscriptions()
    }

    func updateTranscription(_ entry: TranscriptionEntry) {
        if let index = transcriptions.firstIndex(where: { $0.id == entry.id }) {
            transcriptions[index] = entry
            sortTranscriptions()
            saveTranscriptions()
        }
    }

    private func saveTranscriptions() {
        if let encoded = try? JSONEncoder().encode(transcriptions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadTranscriptions() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([TranscriptionEntry].self, from: data) {
            transcriptions = decoded
            sortTranscriptions()
        }
    }

    private func sortTranscriptions() {
        transcriptions.sort { $0.date > $1.date }
    }

    func isAvailable() async -> Bool {
        let supportedLocales = await SpeechTranscriber.supportedLocales
        return !supportedLocales.isEmpty
    }
}