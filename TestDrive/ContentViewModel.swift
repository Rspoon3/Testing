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
    @Published var store: StoreNames = .walmart {
        didSet {
            OfferIDSHolder.shared.totalPoints = 0
            updateItems()
        }
    }
    @Published var items: [ListItem] = []//ListItem.exampleData()
    let decoder = JSONDecoder()
//    var totalPoints: Int {
//        items.flatMap { $0.offers }.map(\.points).reduce(0, +)
//    }
    
    func submit() {
        Task {
            let urlString = "https://dev-offer-search-frostbyte.fetchrewards.com/relatedOffers?offerQuery=\(newItem.lowercased())"
            guard let url = URL(string: urlString) else {
                fatalError()
            }
            
            saving = true
            
                        
            defer {
                newItem.removeAll(keepingCapacity: true)
                suggestedOffer = .example
                saving = false
            }
            
            var request = URLRequest(url: url)
            request.addValue("60bf9b6dd643e46197ef1777", forHTTPHeaderField: "userId")
            
            
            if let name = store.beVariable {
                request.addValue(name, forHTTPHeaderField: "storeName")
            }

                        
            guard
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
    
    
    func updateItems() {
        Task {
            var newItems: [ListItem] = []
            
            for item in items {
                let urlString = "https://dev-offer-search-frostbyte.fetchrewards.com/relatedOffers?offerQuery=\(item.title.lowercased())?storeName\(store.beVariable!)"
                print(urlString)
                guard let url = URL(string: urlString) else {
                    fatalError()
                }
                
                var request = URLRequest(url: url)
                request.addValue("60bf9b6dd643e46197ef1777", forHTTPHeaderField: "userId")
                
//                
//                if let name = store.beVariable {
//                    request.addValue(name, forHTTPHeaderField: "storeName")
//                }
                
                
                guard
                    let (data, _) = try? await URLSession.shared.data(for: request),
                    let offers = try? decoder.decode([Offer].self, from: data)
                else {
                    let item = ListItem(title: item.title, offers: [])
                    print(item.title)
                    newItems.append(item)
                    continue
                }
                
                let item = ListItem(title: item.title, offers: offers)
                newItems.append(item)
            }
            
            items = newItems
        }
    }
}


enum StoreNames: String, CaseIterable, Identifiable {
    case walmart = "Walmart"
    case JEWELOSCO = "Jewl Osco"
    case stopAndshop = "Stop and shop"
    case csv = "CSV"
    case costco = "Costco"
    
    var id: String { rawValue }
    
    var beVariable: String? {
        switch self {
        case .walmart:
            "WALMART"
        case .JEWELOSCO:
            "JEWEL OSCO"
        default: nil
        }
    }
}
