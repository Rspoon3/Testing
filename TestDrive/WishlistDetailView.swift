//
//  WishlistDetailView.swift
//  Testing
//
//  Created by Ricky on 12/21/24.
//
import SwiftUI

struct WishlistDetailView: View {
    let wishlist: Wishlist
    @ObservedObject private var metadataManager: LinkMetadataManager = LinkMetadataManager()
    @State private var newURL: String = ""
    
    var body: some View {
        VStack {
            // URL Entry Field
            TextField("Add URL", text: $newURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // Add Button
            Button("Add Link") {
                if let url = URL(string: newURL) {
                    metadataManager.addLink(url: url, to: wishlist)
                }
                newURL = ""
            }
            .buttonStyle(.bordered)
            
            // Grid View for Links
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(metadataManager.linkItems) { item in
                        LinkPreviewCard(linkItem: item)
                    }
                }
            }
        }
        .onAppear {
            metadataManager.loadLinks(for: wishlist)
        }
        .navigationTitle(wishlist.name)
    }
}
