//
//  WishlistManager.swift
//  Testing
//
//  Created by Ricky on 12/21/24.
//


import SwiftUI
import LinkPresentation
import Combine

class WishlistManager: ObservableObject {
    @Published var wishlists: [Wishlist] = []
    private let userDefaultsKey = "Wishlists"
    
    init() {
        loadWishlists()
    }
    
    // MARK: - CRUD Operations
    func addWishlist(_ name: String) {
        let newWishlist = Wishlist(name: name)
        wishlists.append(newWishlist)
        saveWishlists()
    }
    
    func deleteWishlist(_ wishlist: Wishlist) {
        wishlists.removeAll { $0.id == wishlist.id }
        saveWishlists()
    }
    
    func addLink(to wishlistID: UUID, url: URL) {
        guard let index = wishlists.firstIndex(where: { $0.id == wishlistID }) else { return }
        
        if !wishlists[index].urls.contains(url) {
            wishlists[index].urls.append(url)
            saveWishlists()
        }
    }
    
    func removeLink(from wishlistID: UUID, url: URL) {
        guard let index = wishlists.firstIndex(where: { $0.id == wishlistID }) else { return }
        wishlists[index].urls.removeAll { $0 == url }
        saveWishlists()
    }
    
    // MARK: - Persistence
    private func saveWishlists() {
        if let data = try? JSONEncoder().encode(wishlists) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadWishlists() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedWishlists = try? JSONDecoder().decode([Wishlist].self, from: data) {
            wishlists = savedWishlists
        }
    }
}
