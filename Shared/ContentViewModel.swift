//
//  ContentViewModel.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 12/8/23.
//

import Foundation

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var saving = false
    @Published var suggestedOffer: Offer = .example
    @Published var newItem: String = ""
    @Published var items: [ListItem] = ListItem.exampleData()
    let decoder = JSONDecoder()
    var totalPoints: Int {
        items.flatMap { $0.offers }.map(\.points).reduce(0, +)
    }
    
    func submit() {
        Task {
            let urlString = "https://dev-offer-search-frostbyte.fetchrewards.com/relatedOffers?offerQuery=\(newItem.lowercased())"
            saving = true
            
                        
            defer {
                newItem.removeAll(keepingCapacity: true)
                suggestedOffer = .example
                saving = false
            }
            
            var request = URLRequest(url: URL(string: urlString)!)
            request.addValue("60bf9b6dd643e46197ef1777", forHTTPHeaderField: "userId")
            
            guard
                let url = URL(string: urlString),
                let (data, _) = try? await URLSession.shared.data(for: request),
                let offers = try? decoder.decode([Offer].self, from: data)
            else {
                return
            }
            
            let item = ListItem(title: newItem, offers: offers)
            items.append(item)
            
            
            
//            let t = "https://dev-offer-search-frostbyte.fetchrewards.com/offer/\(offers[0].offerId)"
//            request = URLRequest(url: URL(string: t)!)
//            request.addValue("60bf9b6dd643e46197ef1777", forHTTPHeaderField: "userId")
//
//
//
//            guard
//                let (data, _) = try? await URLSession.shared.data(for: request)
//            else {
//                fatalError()
//            }
//
//            print(data.count)
        }
    }
}
