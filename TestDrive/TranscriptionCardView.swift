import SwiftUI

struct TranscriptionCardView: View {
    let entry: TranscriptionEntry
    let store: TranscriptionStore
    @State private var showingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title)
                .font(.headline)
                .foregroundColor(.primary)

            HStack {
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if let category = entry.category {
                    Image(systemName: category.icon)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            if let summary = entry.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text(String(entry.text.characters))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if entry.hasAudioFile {
                HStack {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(.blue)

                    if let duration = entry.audioDuration {
                        Text(formatTime(duration))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    Spacer()
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            TranscriptionDetailView(entry: entry, store: store)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}