//
//  ListItemRow.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 12/8/23.
//

import SwiftUI

struct ListItemRow: View {
    @State private var showOffers = false
    let item: ListItem
    
    var titleView: some View {
        HStack(spacing: 10) {
            Image(systemName: "circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25)
                .foregroundStyle(.secondary)
            
            Text(item.title)
                .font(.headline)
        }
    }
    
    var body: some View {
        if item.offers.isEmpty {
            titleView
        } else {
            DisclosureGroup(
                content: {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(item.offers) { offer in
                                AsyncImage(url: URL(string: offer.imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 150)
                                        .cornerRadius(8)
                                        .overlay(alignment: .bottom) {
                                            Text(offer.points.formatted())
                                                .fontWeight(.bold)
                                                .padding(.bottom, 4)
                                        }
                                } placeholder: {
                                    Color.orange.opacity(0.1)
                                        .frame(width: 150, height: 150)
                                        .cornerRadius(8)
                                        .overlay {
                                            ProgressView()
                                        }
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                },
                label: {
                    titleView
                }
            )
        }
    }
}
