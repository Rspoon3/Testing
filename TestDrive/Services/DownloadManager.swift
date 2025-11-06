import Foundation
import SwiftData

/// Manages downloading and storing podcast episodes locally.
@Observable
final class DownloadManager: NSObject {
    /// Dictionary tracking download progress by episode ID.
    var downloadProgress: [Int: Double] = [:]

    /// Set of episode IDs currently being downloaded.
    var activeDownloads: Set<Int> = []

    private var urlSession: URLSession!
    private var downloadTasks: [Int: URLSessionDownloadTask] = [:]
    private var episodeCache: [Int: Episode] = [:]
    private let modelContext: ModelContext

    // MARK: - Initializer

    /// Creates a new DownloadManager instance.
    /// - Parameter modelContext: The SwiftData model context for persistence.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init()

        let configuration = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    // MARK: - Public Helpers

    /// Downloads an episode and saves it locally.
    /// - Parameter episode: The episode to download.
    func downloadEpisode(_ episode: Episode) {
        guard !activeDownloads.contains(episode.id), let audioURL = episode.audioURL else { return }

        activeDownloads.insert(episode.id)
        downloadProgress[episode.id] = 0.0
        episodeCache[episode.id] = episode

        let task = urlSession.downloadTask(with: audioURL)
        downloadTasks[episode.id] = task
        task.resume()
    }

    /// Cancels an active download.
    /// - Parameter episodeID: The ID of the episode to cancel downloading.
    func cancelDownload(for episodeID: Int) {
        guard let task = downloadTasks[episodeID] else { return }

        task.cancel()
        downloadTasks.removeValue(forKey: episodeID)
        activeDownloads.remove(episodeID)
        downloadProgress.removeValue(forKey: episodeID)
        episodeCache.removeValue(forKey: episodeID)
    }

    /// Checks if an episode is downloaded.
    /// - Parameter episodeID: The episode ID to check.
    /// - Returns: True if the episode exists in SwiftData, false otherwise.
    @MainActor
    func isDownloaded(episodeID: Int) -> Bool {
        let descriptor = FetchDescriptor<DownloadedEpisode>(
            predicate: #Predicate { $0.episodeID == episodeID }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            return !results.isEmpty
        } catch {
            return false
        }
    }

    /// Retrieves a downloaded episode from storage.
    /// - Parameter episodeID: The episode ID to retrieve.
    /// - Returns: The downloaded episode if found, nil otherwise.
    @MainActor
    func getDownloadedEpisode(episodeID: Int) -> DownloadedEpisode? {
        let descriptor = FetchDescriptor<DownloadedEpisode>(
            predicate: #Predicate { $0.episodeID == episodeID }
        )

        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            return nil
        }
    }

    /// Deletes a downloaded episode.
    /// - Parameter downloadedEpisode: The episode to delete.
    @MainActor
    func deleteEpisode(_ downloadedEpisode: DownloadedEpisode) {
        // Delete the file
        let fileURL = URL(fileURLWithPath: downloadedEpisode.localFilePath)
        try? FileManager.default.removeItem(at: fileURL)

        // Delete from SwiftData
        modelContext.delete(downloadedEpisode)
        try? modelContext.save()
    }

    // MARK: - Private Helpers

    /// Gets the local file path for an episode.
    /// - Parameter episodeID: The episode ID.
    /// - Returns: A URL pointing to where the episode should be stored.
    private func localFileURL(for episodeID: Int) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("episode_\(episodeID).mp3")
    }

    /// Saves episode metadata to SwiftData after download completes.
    /// - Parameters:
    ///   - episode: The episode that was downloaded.
    ///   - localPath: The local file path where the audio is stored.
    private func saveDownloadedEpisode(_ episode: Episode, localPath: String) {
        let downloadedEpisode = DownloadedEpisode(
            episodeID: episode.id,
            title: episode.title,
            episodeDescription: episode.description,
            duration: episode.duration,
            localFilePath: localPath,
            artworkURL: episode.artworkURL?.absoluteString,
            publishDate: episode.publishDate
        )

        Task { @MainActor in
            modelContext.insert(downloadedEpisode)
            try? modelContext.save()
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Find the episode ID for this task
        guard let episodeID = downloadTasks.first(where: { $0.value == downloadTask })?.key else {
            return
        }

        let destinationURL = localFileURL(for: episodeID)

        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // Move downloaded file to permanent location
            try FileManager.default.moveItem(at: location, to: destinationURL)

            // Get episode data from cache
            if let episode = episodeCache[episodeID] {
                saveDownloadedEpisode(episode, localPath: destinationURL.path)
            }

            // Clean up
            downloadTasks.removeValue(forKey: episodeID)
            activeDownloads.remove(episodeID)
            downloadProgress.removeValue(forKey: episodeID)
            episodeCache.removeValue(forKey: episodeID)
        } catch {
            print("Error saving downloaded file: \(error)")
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let episodeID = downloadTasks.first(where: { $0.value == downloadTask })?.key else {
            return
        }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.downloadProgress[episodeID] = progress
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let episodeID = downloadTasks.first(where: { $0.value == task })?.key else {
            return
        }

        if let error {
            print("Download failed for episode \(episodeID): \(error)")
        }

        downloadTasks.removeValue(forKey: episodeID)
        activeDownloads.remove(episodeID)
        downloadProgress.removeValue(forKey: episodeID)
        episodeCache.removeValue(forKey: episodeID)
    }
}
