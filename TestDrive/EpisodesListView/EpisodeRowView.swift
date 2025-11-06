import SwiftUI

/// Displays a single episode row in the episodes list.
struct EpisodeRowView: View {
    private let episode: Episode
    private let isDownloaded: Bool
    private let isDownloading: Bool
    private let downloadProgress: Double?
    private let onDownloadTap: () -> Void
    private let onPlayTap: (() -> Void)?

    // MARK: - Initializer

    /// Creates a new EpisodeRowView.
    /// - Parameters:
    ///   - episode: The episode to display.
    ///   - isDownloaded: Whether the episode is downloaded.
    ///   - isDownloading: Whether the episode is currently downloading.
    ///   - downloadProgress: Optional download progress from 0.0 to 1.0.
    ///   - onDownloadTap: Action to perform when download button is tapped.
    ///   - onPlayTap: Optional action to perform when play button is tapped.
    init(
        episode: Episode,
        isDownloaded: Bool,
        isDownloading: Bool,
        downloadProgress: Double? = nil,
        onDownloadTap: @escaping () -> Void,
        onPlayTap: (() -> Void)? = nil
    ) {
        self.episode = episode
        self.isDownloaded = isDownloaded
        self.isDownloading = isDownloading
        self.downloadProgress = downloadProgress
        self.onDownloadTap = onDownloadTap
        self.onPlayTap = onPlayTap
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(formattedDuration)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            actionButton
        }
        .padding(.vertical, 4)
    }

    // MARK: - Private Views

    private var thumbnail: some View {
        Group {
            if let artworkURL = episode.artworkURL {
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.3))
                }
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.3))
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var actionButton: some View {
        if isDownloaded {
            Button {
                onPlayTap?()
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        } else if isDownloading, let progress = downloadProgress {
            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 30, height: 30)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.blue, lineWidth: 3)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-90))
            }
        } else {
            Button {
                onDownloadTap()
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Private Helpers

    /// Formats the episode publish date for display.
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: episode.publishDate)
    }

    /// Formats the episode duration for display.
    private var formattedDuration: String {
        let hours = Int(episode.duration) / 3600
        let minutes = Int(episode.duration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    List {
        EpisodeRowView(
            episode: Episode(
                id: 1,
                title: "Episode 1: Introduction to Podcasting",
                description: "A great episode about podcasting",
                duration: 3665,
                audioURL: URL(string: "https://example.com/episode.mp3")!,
                publishDate: Date()
            ),
            isDownloaded: false,
            isDownloading: false,
            onDownloadTap: {},
            onPlayTap: {}
        )

        EpisodeRowView(
            episode: Episode(
                id: 2,
                title: "Episode 2: Advanced Topics",
                description: "Deep dive into advanced topics",
                duration: 5400,
                audioURL: URL(string: "https://example.com/episode2.mp3")!,
                publishDate: Date().addingTimeInterval(-86400)
            ),
            isDownloaded: true,
            isDownloading: false,
            onDownloadTap: {},
            onPlayTap: {}
        )

        EpisodeRowView(
            episode: Episode(
                id: 3,
                title: "Episode 3: Downloading",
                description: "Currently downloading",
                duration: 4200,
                audioURL: URL(string: "https://example.com/episode3.mp3")!,
                publishDate: Date().addingTimeInterval(-172800)
            ),
            isDownloaded: false,
            isDownloading: true,
            downloadProgress: 0.65,
            onDownloadTap: {},
            onPlayTap: nil
        )
    }
}
