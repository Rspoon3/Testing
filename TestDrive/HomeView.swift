//
//  HomeView.swift
//  Testing
//
//  Created by Ricky on 12/21/24.
//


import SwiftUI

import SwiftUI

struct HomeView: View {
    @StateObject private var wishlistManager = WishlistManager()
    @State private var newWishlistName: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("New Wishlist Name", text: $newWishlistName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Add Wishlist") {
                    if !newWishlistName.isEmpty {
                        wishlistManager.addWishlist(newWishlistName)
                        newWishlistName = ""
                    }
                }
                .buttonStyle(.bordered)
                
                List {
                    ForEach(wishlistManager.wishlists) { wishlist in
                        NavigationLink(destination: WishlistDetailView(wishlist: wishlist)) {
                            Text(wishlist.name)
                        }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let wishlist = wishlistManager.wishlists[index]
                            wishlistManager.deleteWishlist(wishlist)
                        }
                    }
                }
            }
            .navigationTitle("Wishlists")
        }
    }
}
