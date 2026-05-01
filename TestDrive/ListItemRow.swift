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
            NavigationLink {
                ListItemOffersView(
                    title: item.title,
                    offers: item.offers
                )
            } label: {
                titleView
            }
        }
    }
}
