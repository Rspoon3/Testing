//
//  ListItemOffersView.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 12/8/23.
//

import SwiftUI

final class OfferIDSHolder: ObservableObject {
    @Published var checkOffersIds: Set<String> = []
    static let shared = OfferIDSHolder()
    @Published var totalPoints = 0
}


struct ListItemOffersView: View {
    let title: String
    let offers: [Offer]
    private let size: CGFloat = 100
    @ObservedObject var offerIDSHolder = OfferIDSHolder.shared
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ]) {
                ForEach(offers, id: \.points) { offer in
                    AsyncImage(url: URL(string: offer.imageUrl)) { image in
                        VStack {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(8)
                                .frame(height: size)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: offerIDSHolder.checkOffersIds.contains(offer.id) ? "star.fill" : "star")
                                        .foregroundStyle(.yellow)
                                        .padding(.all, 2)
                                }
                            
                            Text(offer.points.formatted())
                                .fontWeight(.bold)
                                .padding(.bottom, 4)
                        }
                    } placeholder: {
                        VStack {
                            Color.orange.opacity(0.1)
                                .frame(width: size, height: size)
                                .cornerRadius(8)
                                .overlay {
                                    ProgressView()
                                }
                            Text("")
                                .fontWeight(.bold)
                                .padding(.bottom, 4)
                        }
                    }
                    .onTapGesture {
                        if offerIDSHolder.checkOffersIds.contains(offer.id) {
                            offerIDSHolder.checkOffersIds.remove(offer.id)
                            offerIDSHolder.totalPoints -= offer.points
                        } else {
                            offerIDSHolder.checkOffersIds.insert(offer.id)
                            offerIDSHolder.totalPoints += offer.points
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(title)
    }
}

#Preview {
    NavigationStack {
        ListItemOffersView(
            title: "Title",
            offers: Offer.examples()
        )
    }
}
