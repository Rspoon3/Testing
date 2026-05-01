import SwiftUI
import AVFoundation

struct NewTranscriptionView: View {
    let store: TranscriptionStore
    @Environment(\.dismiss) private var dismiss

    @State private var entry = TranscriptionEntry.blank()
    @State private var transcriber: SpokenWordTranscriber? = nil
    @State private var recorder: AudioRecorder? = nil
    @State private var isRecording = false
    @State private var isStopping = false
    @State private var isProcessingAI = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Transcription Title", text: $entry.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                VStack(spacing: 16) {
                    Button {
                        Task {
                            if isRecording {
                                await stopRecording()
                            } else {
                                await startRecording()
                            }
                        }
                    } label: {
                        HStack {
                            if isStopping {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Stopping...")
                            } else {
                                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.title2)
                                Text(isRecording ? "Stop Recording" : "Start Recording")
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color.red : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isStopping || isProcessingAI)

                    if isRecording {
                        Text("Recording...")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if isStopping {
                        Text("Finishing transcription...")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if isProcessingAI {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Processing with AI...")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Transcription Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transcription")
                                .font(.headline)
                                .foregroundColor(.primary)

                            if !entry.text.characters.isEmpty {
                                Text(entry.text)
                                    .font(.body)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            } else {
                                Text("Your transcription will appear here...")
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }

                            if let transcriber = transcriber, !transcriber.volatileTranscript.characters.isEmpty {
                                Text(transcriber.volatileTranscript)
                                    .font(.body)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }

                        // AI Results Section (only show after processing completes)
                        if !isProcessingAI && !isStopping {
                            // Summary
                            if let summary = entry.summary, !summary.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("AI Summary")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text(summary)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding()
                                        .background(Color(.systemBlue).opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }

                            // Category
                            if let category = entry.category {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Label(category.rawValue, systemImage: category.icon)
                                        .font(.body)
                                        .foregroundColor(.blue)
                                        .padding()
                                        .background(Color(.systemBlue).opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }

                            // Key Points
                            if let keyPoints = entry.keyPoints, !keyPoints.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Key Points")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(keyPoints, id: \.self) { point in
                                            HStack(alignment: .top) {
                                                Text("•")
                                                    .foregroundColor(.blue)
                                                Text(point)
                                                    .font(.body)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemBlue).opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("New Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isStopping || isProcessingAI)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(isStopping || isProcessingAI)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func startRecording() async {
        do {
            transcriber = SpokenWordTranscriber(entry: $entry)
            recorder = AudioRecorder(transcriber: transcriber!, entry: $entry)

            try await recorder?.startRecording()
            isRecording = true
        } catch {
            alertMessage = "Failed to start recording: \(error.localizedDescription)"
            showingAlert = true
            isRecording = false
        }
    }

    private func stopRecording() async {
        guard !isStopping else { return }
        isStopping = true

        do {
            // First stop the recording and wait for transcription to fully complete
            try await recorder?.stopRecording()
            isRecording = false

            // Wait a moment for transcription to fully finish
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            isStopping = false

            // Now process with AI after transcription is complete
            let textContent = String(entry.text.characters).trimmingCharacters(in: .whitespacesAndNewlines)
            if !textContent.isEmpty {
                isProcessingAI = true

                do {
                    print("Starting AI processing with text: \(textContent.prefix(100))...")

                    // Use Swift concurrency to run AI tasks concurrently
                    async let titleTask = AIManager.shared.generateTitle(for: textContent)
                    async let summaryTask = AIManager.shared.generateSummary(for: textContent)
                    async let categoryTask = AIManager.shared.classifyContent(for: textContent)
                    async let keyPointsTask = AIManager.shared.extractKeyPoints(for: textContent)

                    let (newTitle, newSummary, newCategory, newKeyPoints) = try await (titleTask, summaryTask, categoryTask, keyPointsTask)

                    // Update the entry with AI results
                    if let newTitle = newTitle, entry.title == "New Transcription" || entry.title.isEmpty {
                        entry.title = newTitle
                        print("✅ Updated title to: \(newTitle)")
                    }

                    entry.summary = newSummary
                    entry.category = newCategory
                    entry.keyPoints = newKeyPoints

                    print("✅ AI processing completed successfully")
                    print("   Title: \(entry.title)")
                    print("   Summary: \(newSummary?.prefix(50) ?? "nil")")
                    print("   Category: \(newCategory?.rawValue ?? "nil")")
                    print("   Key Points: \(newKeyPoints?.count ?? 0) items")

                } catch {
                    print("❌ AI processing failed: \(error)")
                }

                isProcessingAI = false

                // Auto-save after AI processing completes (but don't dismiss)
                entry.isDone = true
                store.addTranscription(entry)
            }
        } catch {
            isStopping = false
            isRecording = false
            alertMessage = "Failed to stop recording: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func saveTranscription() {
        entry.isDone = true
        store.addTranscription(entry)
        dismiss()
    }
}