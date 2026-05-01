import SwiftUI

struct TranscriptionDetailView: View {
    @State var entry: TranscriptionEntry
    let store: TranscriptionStore
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedText: String = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    TextField("Title", text: $editedTitle)
                        .font(.title2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(entry.title)
                        .font(.title2)
                        .bold()
                }

                HStack {
                    Text(entry.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if let category = entry.category {
                        Label(category.rawValue, systemImage: category.icon)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                if entry.hasAudioFile, let audioURL = entry.url {
                    AudioPlayerView(audioURL: audioURL)
                        .padding(.vertical, 8)
                }

                if let summary = entry.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Summary")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(summary)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                }

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
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                }

                Divider()

                if isEditing {
                    TextEditor(text: $editedText)
                        .font(.body)
                } else {
                    ScrollView {
                        Text(entry.text)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isEditing {
                            Button("Cancel") {
                                cancelEditing()
                            }
                            Button("Save") {
                                saveChanges()
                            }
                        } else {
                            HStack(spacing: 12) {
                                if AIManager.shared.isAvailable {
                                    Menu {
                                        Button("Generate Summary") {
                                            Task {
                                                try? await entry.generateSummary()
                                                store.updateTranscription(entry)
                                            }
                                        }
                                        Button("Extract Key Points") {
                                            Task {
                                                try? await entry.extractKeyPoints()
                                                store.updateTranscription(entry)
                                            }
                                        }
                                        Button("Regenerate Title") {
                                            Task {
                                                if let newTitle = try? await entry.suggestedTitle() {
                                                    entry.title = newTitle
                                                    store.updateTranscription(entry)
                                                }
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "brain.head.profile")
                                            .foregroundColor(.purple)
                                    }
                                }

                                Menu {
                                    Button("Edit") {
                                        startEditing()
                                    }
                                    Button("Delete", role: .destructive) {
                                        deleteTranscription()
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            editedTitle = entry.title
            editedText = String(entry.text.characters)
        }
    }

    private func startEditing() {
        isEditing = true
    }

    private func cancelEditing() {
        isEditing = false
        editedTitle = entry.title
        editedText = String(entry.text.characters)
    }

    private func saveChanges() {
        entry.title = editedTitle
        entry.text = AttributedString(editedText)
        store.updateTranscription(entry)
        isEditing = false
    }

    private func deleteTranscription() {
        entry.deleteAudioFile()
        store.deleteTranscription(entry)
        dismiss()
    }
}