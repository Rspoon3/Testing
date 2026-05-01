//
//  LinkMetadataManager.swift
//  Testing
//
//  Created by Ricky on 12/21/24.
//
import LinkPresentation
import SwiftUI
import Combine

class LinkMetadataManager: ObservableObject {
    @Published var linkItems: [LinkItem] = []
    
    /// Load all URLs for a given wishlist
    func loadLinks(for wishlist: Wishlist) {
        DispatchQueue.main.async {
            self.linkItems.removeAll()
        }
        
        for url in wishlist.urls {
            var newItem = LinkItem(url: url)
            if let metadata = LinkMetadataCache.shared.loadMetadata(for: url) {
                newItem.metadata = metadata
                DispatchQueue.main.async {
                    self.linkItems.append(newItem)
                }
            } else {
                let metadataProvider = LPMetadataProvider()
                DispatchQueue.global(qos: .background).async {
                    metadataProvider.startFetchingMetadata(for: url) { metadata, error in
                        if let metadata = metadata {
                            LinkMetadataCache.shared.saveMetadata(metadata, for: url)
                            DispatchQueue.main.async {
                                newItem.metadata = metadata
                                self.linkItems.append(newItem)
                            }
                        } else {
                            print("❌ Failed to fetch metadata: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
            }
        }
    }
    
    /// Add a new URL to a wishlist
    func addLink(url: URL, to wishlist: Wishlist) {
        var newItem = LinkItem(url: url)
        let metadataProvider = LPMetadataProvider()
        
        DispatchQueue.global(qos: .background).async {
            metadataProvider.startFetchingMetadata(for: url) { metadata, error in
                if let metadata = metadata {
                    LinkMetadataCache.shared.saveMetadata(metadata, for: url)
                    DispatchQueue.main.async {
                        newItem.metadata = metadata
                        self.linkItems.append(newItem)
                    }
                } else {
                    print("❌ Failed to fetch metadata: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}
