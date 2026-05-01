import Foundation
import Speech
import SwiftUI

@Observable
final class SpokenWordTranscriber {
    private var inputSequence: AsyncStream<AnalyzerInput>?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var recognizerTask: Task<(), Error>?

    static let magenta = Color(red: 0.54, green: 0.02, blue: 0.6).opacity(0.8)

    var analyzerFormat: AVAudioFormat?

    var converter = BufferConverter()
    var downloadProgress: Progress?

    var entry: Binding<TranscriptionEntry>

    var volatileTranscript: AttributedString = ""
    var finalizedTranscript: AttributedString = ""

    static let locale = Locale(components: .init(languageCode: .english, script: nil, languageRegion: .unitedStates))

    init(entry: Binding<TranscriptionEntry>) {
        self.entry = entry
    }

    func setUpTranscriber() async throws {
        let locale = Locale.current

        // First, allocate the locale if needed
        try await allocateLocaleIfNeeded(locale: locale)

        transcriber = SpeechTranscriber(locale: locale,
                                        transcriptionOptions: [],
                                        reportingOptions: [.volatileResults],
                                        attributeOptions: [.audioTimeRange])

        guard let transcriber else {
            throw TranscriptionError.failedToSetupRecognitionStream
        }

        analyzer = SpeechAnalyzer(modules: [transcriber])

        do {
            try await ensureModel(transcriber: transcriber, locale: locale)
        } catch let error as TranscriptionError {
            print(error)
            return
        }

        self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()

        guard let inputSequence else { return }

        recognizerTask = Task {
            do {
                for try await case let result in transcriber.results {
                    let text = result.text
                    if result.isFinal {
                        finalizedTranscript += text
                        volatileTranscript = ""
                        updateEntryWithNewText(withFinal: text)
                    } else {
                        volatileTranscript = text
                        volatileTranscript.foregroundColor = .purple.opacity(0.4)
                    }
                }
            } catch {
                print("speech recognition failed")
            }
        }

        try await analyzer?.start(inputSequence: inputSequence)
    }

    func updateEntryWithNewText(withFinal str: AttributedString) {
        entry.text.wrappedValue.append(str)
    }

    func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer) async throws {
        guard let inputBuilder, let analyzerFormat else {
            throw TranscriptionError.invalidAudioDataType
        }

        let converted = try self.converter.convertBuffer(buffer, to: analyzerFormat)
        let input = AnalyzerInput(buffer: converted)

        inputBuilder.yield(input)
    }

    public func finishTranscribing() async throws {
        inputBuilder?.finish()
        try await analyzer?.finalizeAndFinishThroughEndOfInput()
        recognizerTask?.cancel()
        recognizerTask = nil

        // Clean up resources
        await cleanup()
    }

    public func cleanup() async {
        // Cancel any ongoing recognition task
        recognizerTask?.cancel()
        recognizerTask = nil

        // Clear transcriber and analyzer references
        transcriber = nil
        analyzer = nil

        // Release locale resources - but only release the current locale, not all
        // to avoid affecting other transcription sessions
    }
}

extension SpokenWordTranscriber {
    private func allocateLocaleIfNeeded(locale: Locale) async throws {
        // Check if the locale is already allocated
        let reservedLocales = await AssetInventory.reservedLocales
        let localeIdentifier = locale.identifier(.bcp47)

        // Check if locale is already reserved
        if reservedLocales.contains(where: { locale in
            locale.identifier(.bcp47) == localeIdentifier
        }) {
            print("Locale \(localeIdentifier) is already allocated")
            return
        }

        print("Allocating locale: \(localeIdentifier)")

        // If we have too many reserved locales, release one to make room
        // The system typically supports a limited number of reserved locales
        if reservedLocales.count >= 3 { // Conservative limit
            print("At reserved locales limit, releasing oldest...")
            // Release the oldest locale to make room
            if let oldestLocale = reservedLocales.first {
                print("Releasing locale: \(oldestLocale.identifier(.bcp47))")
                await AssetInventory.release(reservedLocale: oldestLocale)
            }
        }

        // The actual "allocation" in iOS 18+ happens through downloading the model
        // if it's not already installed on the device
        if !(await installed(locale: locale)) {
            print("Locale \(localeIdentifier) not installed, downloading...")
            // This will install and effectively "allocate" the locale
            let transcriber = SpeechTranscriber(locale: locale, transcriptionOptions: [], reportingOptions: [], attributeOptions: [])
            try await downloadIfNeeded(for: transcriber)
        }

        print("Successfully allocated locale: \(localeIdentifier)")
    }

    public func ensureModel(transcriber: SpeechTranscriber, locale: Locale) async throws {
        guard await supported(locale: locale) else {
            throw TranscriptionError.localeNotSupported
        }

        if await installed(locale: locale) {
            return
        } else {
            try await downloadIfNeeded(for: transcriber)
        }
    }

    func supported(locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        return supported.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }

    func installed(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        return installed.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }

    func downloadIfNeeded(for module: SpeechTranscriber) async throws {
        if let downloader = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            self.downloadProgress = downloader.progress
            try await downloader.downloadAndInstall()
        }
    }

    func releaseLocales() async {
        let reserved = await AssetInventory.reservedLocales
        for locale in reserved {
            await AssetInventory.release(reservedLocale: locale)
        }
    }
}

public enum TranscriptionError: Error {
    case couldNotDownloadModel
    case failedToSetupRecognitionStream
    case invalidAudioDataType
    case localeNotSupported
    case localeAllocationFailed
    case noInternetForModelDownload
    case audioFilePathNotFound

    var descriptionString: String {
        switch self {
        case .couldNotDownloadModel:
            return "Could not download the model."
        case .failedToSetupRecognitionStream:
            return "Could not set up the speech recognition stream."
        case .invalidAudioDataType:
            return "Unsupported audio format."
        case .localeNotSupported:
            return "This locale is not yet supported by SpeechAnalyzer."
        case .noInternetForModelDownload:
            return "The model could not be downloaded because the user is not connected to internet."
        case .localeAllocationFailed:
            return "Failed to allocate the required locale for speech recognition."
        case .audioFilePathNotFound:
            return "Couldn't write audio to file."
        }
    }
}