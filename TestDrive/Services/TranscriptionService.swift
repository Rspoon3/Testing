import Foundation
import Speech
import AVFoundation

/// Protocol for transcription services.
protocol TranscriptionServiceProtocol: AnyObject {
    var transcriptionText: String { get set }
    var isTranscribing: Bool { get set }
    var isInstallingModel: Bool { get set }
    var modelInstallationProgress: Double { get set }
    var errorMessage: String? { get set }

    func requestAuthorization() async -> Bool
    func installModelIfNeeded() async throws
    func transcribe(fileURL: URL) async
    func cancelTranscription()
}

/// Custom errors for transcription.
enum TranscriptionError: LocalizedError {
    case localeNotSupported
    case modelInstallationFailed
    case authorizationDenied
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .localeNotSupported:
            return "This language is not supported for transcription"
        case .modelInstallationFailed:
            return "Failed to download the speech recognition model"
        case .authorizationDenied:
            return "Speech recognition authorization denied"
        case .fileNotFound:
            return "Audio file not found"
        }
    }
}

/// Service for transcribing podcast episodes using the new SpeechAnalyzer API.
@available(iOS 26.0, *)
@Observable
final class TranscriptionService: TranscriptionServiceProtocol {
    /// Current transcription text.
    var transcriptionText: String = ""

    /// Whether transcription is in progress.
    var isTranscribing = false

    /// Whether model installation is in progress.
    var isInstallingModel = false

    /// Model installation progress (0.0 to 1.0).
    var modelInstallationProgress: Double = 0

    /// Error message if transcription fails.
    var errorMessage: String?

    private var transcriptionTask: Task<Void, Never>?
    private let locale = Locale(components: .init(languageCode: .english, languageRegion: .unitedStates))

    // MARK: - Public Helpers

    /// Requests authorization for speech recognition.
    /// - Returns: True if authorized, false otherwise.
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    /// Installs the speech recognition model if needed.
    /// - Throws: TranscriptionError if installation fails or locale is not supported.
    func installModelIfNeeded() async throws {
        let localeIdentifier = locale.identifier(.bcp47)

        // Check if already installed
        let installedLocales = await SpeechTranscriber.installedLocales
        if installedLocales.map({ $0.identifier(.bcp47) }).contains(localeIdentifier) {
            return
        }

        // Check if supported
        let supportedLocales = await SpeechTranscriber.supportedLocales
        guard supportedLocales.map({ $0.identifier(.bcp47) }).contains(localeIdentifier) else {
            throw TranscriptionError.localeNotSupported
        }

        isInstallingModel = true
        modelInstallationProgress = 0
        errorMessage = nil

        do {
            // Create a temporary transcriber to determine what needs to be downloaded
            let tempTranscriber = SpeechTranscriber(locale: locale, preset: .transcription)

            // Request model installation with the transcriber
            if let downloader = try await AssetInventory.assetInstallationRequest(supporting: [tempTranscriber]) {
                // Monitor progress
                let progress = downloader.progress

                // Observe progress changes
                Task {
                    while !Task.isCancelled && !progress.isFinished {
                        await MainActor.run {
                            modelInstallationProgress = progress.fractionCompleted
                        }
                        try? await Task.sleep(for: .milliseconds(100))
                    }
                }

                // Download and install
                try await downloader.downloadAndInstall()
            }

            isInstallingModel = false
        } catch {
            isInstallingModel = false
            throw TranscriptionError.modelInstallationFailed
        }
    }

    /// Transcribes an audio file using the new SpeechAnalyzer API.
    /// - Parameter fileURL: URL to the audio file.
    func transcribe(fileURL: URL) async {
        // Cancel any existing task
        transcriptionTask?.cancel()

        transcriptionTask = Task {
            isTranscribing = true
            errorMessage = nil
            transcriptionText = ""

            do {
                // Install model if needed
                try await installModelIfNeeded()

                // Create transcriber with transcription preset
                let transcriber = SpeechTranscriber(
                    locale: locale,
                    preset: .transcription
                )

                // Create analyzer with the transcriber module
                let analyzer = SpeechAnalyzer(modules: [transcriber])

                // Process results in a separate task
                let resultsTask = Task {
                    for try await result in transcriber.results {
                        // Update with both volatile and finalized results
                        if !Task.isCancelled {
                            transcriptionText += String(result.text.characters) + " "
                        }
                    }
                }

                // Create AVAudioFile from URL
                let audioFile = try AVAudioFile(forReading: fileURL)

                // Analyze the audio file
                if let lastSample = try await analyzer.analyzeSequence(from: audioFile) {
                    try await analyzer.finalizeAndFinish(through: lastSample)
                }

                // Wait for all results to be processed
                try await resultsTask.value

                isTranscribing = false
            } catch let error as TranscriptionError {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                    isTranscribing = false
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = "Transcription failed: \(error.localizedDescription)"
                    isTranscribing = false
                }
            }
        }

        await transcriptionTask?.value
    }

    /// Cancels the current transcription task.
    func cancelTranscription() {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        isTranscribing = false
    }
}
