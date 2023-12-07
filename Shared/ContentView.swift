//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import LoremSwiftum

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
                                    ProgressView()
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

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            HStack(spacing: 3) {
                Circle()
                    .foregroundStyle(.yellow)
                    .frame(width: 15)
                    .foregroundStyle(.secondary)
                Text(viewModel.totalPoints.formatted())
                    .foregroundStyle(.primary)
                    .fontWeight(.bold)
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .padding(.leading)
            }
            .padding(.vertical)
            .padding(.leading, 30)
            .padding(.trailing, 10)
            .background {
                Color.black.opacity(0.1)
            }
            .cornerRadius(10)
            
            HStack(spacing: 3) {
                Image(systemName: "car.circle.fill")
                    .foregroundStyle(.blue)
                
                Text("Ralphs")
                    .foregroundStyle(.primary)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 30)
            .background {
                Capsule()
                    .foregroundStyle(.black.opacity(0.1))
            }
            
            List {
                ForEach(viewModel.items) { item in
                    ListItemRow(item: item)
                }
                
                TextField(text: $viewModel.newItem) {
                    HStack {
                        Text("Add Item")
                        if viewModel.saving {
                            ProgressView()
                        }
                    }
                }
                .onSubmit() {
                    viewModel.submit()
                }
            }
            .listStyle(.plain)
            
            
            HStack(spacing: 10) {
                //                Text(viewModel.suggestedOffer.title)
                
                HStack(spacing: 3) {
                    Circle()
                        .foregroundStyle(.yellow)
                        .frame(width: 15)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalPoints.formatted())
                        .foregroundStyle(.primary)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background {
                Color.black.opacity(0.1)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Offer: Decodable, Identifiable, Sendable {
    var id: String { offerId }
    let offerId: String
    let imageUrl: String
    let points: Int
    
    static let example: Offer = Offer(
        offerId: UUID().uuidString,
        imageUrl: "https://image-resize.fetchrewards.com/deals/06e6e768e4c185342a7ff25fe1abab51b7e93da2.jpeg",
        points: Int.random(in: 1..<10_000)
    )
}


struct ListItem: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let offers: [Offer]
    
    static func exampleData() -> [ListItem] {
        let array = (0..<5)
        
        return array.map { _ in
            ListItem(
                title: Lorem.words(Int.random(in: 1..<3)),
                offers: Bool.random() ? [] : [Offer.example, .example, .example, .example , .example, .example, .example, .example]
            )
        }
    }
}

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
            
            guard
                let url = URL(string: urlString),
                let (data, _) = try? await URLSession.shared.data(from: url),
                let offers = try? decoder.decode([Offer].self, from: data)
            else {
                return
            }
            
            let item = ListItem(title: newItem, offers: offers)
            items.append(item)
        }
    }
}
