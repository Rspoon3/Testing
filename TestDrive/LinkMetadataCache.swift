//
//  LinkMetadataCache.swift
//  Testing
//
//  Created by Ricky on 12/21/24.
//

import LinkPresentation
import SwiftUI
import CryptoKit

import LinkPresentation
import SwiftUI
import CryptoKit

class LinkMetadataCache {
    static let shared = LinkMetadataCache()
    
    private let cache = NSCache<NSURL, LPLinkMetadata>()
    private let cacheDirectory: URL
    private let urlsKey = "CachedLinkURLs"
    
    private init() {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectory = urls[0].appendingPathComponent("LinkMetadataCache")
        
        // Ensure cache directory exists
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - File Management
    
    private func filePath(for url: URL) -> URL {
        return cacheDirectory.appendingPathComponent(url.absoluteString.sha256())
    }
    
    // Save Metadata to Disk
    func saveMetadata(_ metadata: LPLinkMetadata, for url: URL) {
        let nsURL = url as NSURL
        cache.setObject(metadata, forKey: nsURL)
        
        let path = filePath(for: url)
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
            try data.write(to: path)
        } catch {
            print("Failed to save metadata to disk: \(error.localizedDescription)")
        }
        
        saveURLToDefaults(url)
    }
    
    // Load Metadata from Disk
    func loadMetadata(for url: URL) -> LPLinkMetadata? {
        let nsURL = url as NSURL
        
        if let metadata = cache.object(forKey: nsURL) {
            return metadata
        }
        
        let path = filePath(for: url)
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: path)
            if let metadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data) {
                cache.setObject(metadata, forKey: nsURL)
                return metadata
            }
        } catch {
            print("Failed to load metadata from disk: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Persistent URL List Management
    
    private func saveURLToDefaults(_ url: URL) {
        var savedURLs = getSavedURLs()
        if !savedURLs.contains(url) {
            savedURLs.append(url)
            let urlStrings = savedURLs.map { $0.absoluteString }
            UserDefaults.standard.set(urlStrings, forKey: urlsKey)
            UserDefaults.standard.synchronize()
            print("✅ URL saved to UserDefaults: \(url)")
        }
    }
    
    func getSavedURLs() -> [URL] {
        let urlStrings = UserDefaults.standard.array(forKey: urlsKey) as? [String] ?? []
        let urls = urlStrings.compactMap { URL(string: $0) }
        print("🔄 Loaded URLs from UserDefaults: \(urls)")
        return urls
    }
    
    // Clear all data (useful for debugging)
    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        UserDefaults.standard.removeObject(forKey: urlsKey)
    }
}
