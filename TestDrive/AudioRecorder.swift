import Foundation
import AVFoundation
import SwiftUI

class AudioRecorder {
    private var outputContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation? = nil
    private let audioEngine: AVAudioEngine
    private let transcriber: SpokenWordTranscriber
    var playerNode: AVAudioPlayerNode?

    var entry: Binding<TranscriptionEntry>

    var file: AVAudioFile?
    private let url: URL
    private var isRecording = false

    init(transcriber: SpokenWordTranscriber, entry: Binding<TranscriptionEntry>) {
        audioEngine = AVAudioEngine()
        self.transcriber = transcriber
        self.entry = entry

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "recording_\(entry.wrappedValue.id.uuidString).wav"
        self.url = documentsPath.appendingPathComponent(fileName)
    }

    func startRecording() async throws {
        guard !isRecording else { return }

        self.entry.url.wrappedValue = url
        guard await isAuthorized() else {
            print("user denied mic permission")
            return
        }
#if os(iOS)
        try setUpAudioSession()
#endif
        try await transcriber.setUpTranscriber()

        isRecording = true
        try setupAudioEngine()

        audioEngine.inputNode.installTap(onBus: 0,
                                         bufferSize: 4096,
                                         format: audioEngine.inputNode.outputFormat(forBus: 0)) { [weak self] (buffer, time) in
            guard let self = self, self.isRecording else { return }
            self.writeBufferToDisk(buffer: buffer)

            Task {
                try? await self.transcriber.streamAudioToTranscriber(buffer)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stopRecording() async throws {
        guard isRecording else { return }

        isRecording = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        if let audioFile = file {
            print("Finalizing audio file at: \(url.path)")
            print("File length: \(audioFile.length) frames")
        }

        file = nil

        entry.isDone.wrappedValue = true

        try await transcriber.finishTranscribing()
    }

    func pauseRecording() {
        audioEngine.pause()
    }

    func resumeRecording() throws {
        try audioEngine.start()
    }

#if os(iOS)
    func setUpAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
#endif


    private func setupAudioEngine() throws {
        let inputSettings = audioEngine.inputNode.inputFormat(forBus: 0).settings
        self.file = try AVAudioFile(forWriting: url,
                                    settings: inputSettings)

        audioEngine.inputNode.removeTap(onBus: 0)
    }

    func playRecording() {
        guard let file else {
            return
        }

        playerNode = AVAudioPlayerNode()
        guard let playerNode else {
            return
        }

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode,
                            to: audioEngine.outputNode,
                            format: file.processingFormat)

        playerNode.scheduleFile(file,
                                at: nil,
                                completionCallbackType: .dataPlayedBack) { _ in
        }

        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("error")
        }
    }

    func stopPlaying() {
        audioEngine.stop()
    }

    func isAuthorized() async -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            return true
        }

        return await AVCaptureDevice.requestAccess(for: .audio)
    }

    func writeBufferToDisk(buffer: AVAudioPCMBuffer) {
        do {
            try self.file?.write(from: buffer)
        } catch {
            print("file writing error: \(error)")
        }
    }
}