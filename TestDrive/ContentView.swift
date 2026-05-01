//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

enum Genre: String, Hashable, CaseIterable {
    case action = "Action"
    case horror = "Horror"
    case fiction = "Fiction"
    case kids = "Kids"
}

struct Movie: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let genre: Genre
}

struct ContentView: View {
    @State private var selectedGenre: Genre?
    @State private var path: [String] = []
    
    private let movies = [
        Movie(name: "Superman", genre: .action),
        Movie(name: "28 Days Later", genre: .horror),
        Movie(name: "World War Z", genre: .horror),
        Movie(name: "Finding Nemo", genre: .kids),
        Movie(name: "Harry Potter 1", genre: .fiction),
        Movie(name: "Harry Potter 2", genre: .fiction),
        Movie(name: "Harry Potter 3", genre: .fiction),
        Movie(name: "Dune", genre: .fiction),
    ]
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedGenre) {
                ForEach(Genre.allCases, id: \.rawValue) { genre in
//                    NavigationLink(genre.rawValue, value: genre)
                    Text(genre.rawValue)
                        .tag(genre)
                }
            }
            .navigationTitle("Genres")
        } detail: {
            let filteredMovies = movies.filter { $0.genre == selectedGenre }
            
            NavigationStack {
                List(filteredMovies) { movie in
                    NavigationLink(movie.name) {
                        Text("\(movie.name) Details View")
                    }
                }
                .navigationTitle(selectedGenre?.rawValue ?? "")
            }
        }
    }
}

#Preview("ContentView") {
    ContentView()
}
