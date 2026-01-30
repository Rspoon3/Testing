import Foundation
import UIKit

/// Service for fetching and caching domain logos/favicons.
///
/// Uses Google Favicon API with three-layer caching:
/// 1. URLCache (HTTP-level caching)
/// 2. NSCache (in-memory for immediate access)
/// 3. FileManager (disk cache for offline support)
@MainActor
public final class DomainLogoService {

    // MARK: - Singleton

    public static let shared = DomainLogoService()

    // MARK: - Properties

    private let imageCache: NSCache<NSString, UIImage>
    private let diskCacheURL: URL
    private let urlSession: URLSession
    private let maxCacheSizeBytes: Int = 50 * 1024 * 1024 // 50MB
    private let cacheExpiryDays: Int = 7

    // MARK: - Initialization

    public init() {
        // Setup in-memory cache
        self.imageCache = NSCache<NSString, UIImage>()
        self.imageCache.countLimit = 100

        // Setup disk cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.diskCacheURL = cacheDir.appendingPathComponent("domain-logos", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        // Setup URL session with caching
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache.shared
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 10
        self.urlSession = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Fetches a logo for the given domain.
    ///
    /// Checks caches first (memory → disk → network), returns nil if unavailable.
    ///
    /// - Parameter domain: The domain to fetch a logo for (e.g., "apple.com")
    /// - Returns: UIImage if available, nil otherwise (triggers fallback in UI)
    public func logo(for domain: String) async -> UIImage? {
        let cleanDomain = sanitizeDomain(domain)
        guard !cleanDomain.isEmpty else { return nil }

        // Check memory cache
        if let cached = loadFromMemoryCache(domain: cleanDomain) {
            return cached
        }

        // Check disk cache
        if let cached = await loadFromDiskCache(domain: cleanDomain) {
            // Store in memory for next time
            imageCache.setObject(cached, forKey: cleanDomain as NSString)
            return cached
        }

        // Fetch from network
        if let fetched = await fetchFromNetwork(domain: cleanDomain) {
            // Cache in memory and disk
            imageCache.setObject(fetched, forKey: cleanDomain as NSString)
            await saveToDiskCache(image: fetched, domain: cleanDomain)
            return fetched
        }

        return nil
    }

    /// Clears expired cache entries (files older than 7 days).
    ///
    /// Call this on app launch to maintain cache size.
    public func clearExpiredCache() async {
        await Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }

            let fileManager = FileManager.default
            guard let files = try? fileManager.contentsOfDirectory(
                at: await self.diskCacheURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            ) else { return }

            let expiryDate = Date().addingTimeInterval(-Double(await self.cacheExpiryDays) * 24 * 60 * 60)

            for fileURL in files {
                if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                   let modificationDate = attributes[.modificationDate] as? Date,
                   modificationDate < expiryDate {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        }.value
    }

    // MARK: - Private Helpers - Memory Cache

    private func loadFromMemoryCache(domain: String) -> UIImage? {
        imageCache.object(forKey: domain as NSString)
    }

    // MARK: - Private Helpers - Disk Cache

    private func loadFromDiskCache(domain: String) async -> UIImage? {
        await Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return nil }
            let fileURL = await self.diskCacheURL.appendingPathComponent("\(domain).png")

            guard let data = try? Data(contentsOf: fileURL),
                  let image = UIImage(data: data) else {
                return nil
            }

            return image
        }.value
    }

    private func saveToDiskCache(image: UIImage, domain: String) async {
        await Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            let fileURL = await self.diskCacheURL.appendingPathComponent("\(domain).png")

            if let data = image.pngData() {
                try? data.write(to: fileURL)
            }
        }.value
    }

    // MARK: - Private Helpers - Network

    private func fetchFromNetwork(domain: String) async -> UIImage? {
        // Google Favicon API
        guard let url = URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64") else {
            return nil
        }

        do {
            let (data, _) = try await urlSession.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    // MARK: - Private Helpers - Domain Sanitization

    /// Sanitizes a domain string by removing protocol, paths, ports, and extracting root domain.
    ///
    /// Examples:
    /// - "https://api.github.com/v1" → "github.com"
    /// - "subdomain.example.com:8080" → "example.com"
    /// - "example.com/path" → "example.com"
    private func sanitizeDomain(_ domain: String) -> String {
        var clean = domain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove protocol
        if let range = clean.range(of: "://") {
            clean = String(clean[range.upperBound...])
        }

        // Remove path and query
        if let slashIndex = clean.firstIndex(of: "/") {
            clean = String(clean[..<slashIndex])
        }

        // Remove port
        if let colonIndex = clean.firstIndex(of: ":") {
            clean = String(clean[..<colonIndex])
        }

        // Extract root domain from subdomain (e.g., "api.github.com" → "github.com")
        let components = clean.components(separatedBy: ".")
        if components.count > 2 {
            // Keep last two components (domain + TLD)
            clean = components.suffix(2).joined(separator: ".")
        }

        return clean
    }
}
