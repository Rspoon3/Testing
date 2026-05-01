//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import SharingGRDB

struct ContentView: View {
    @Dependency(\.defaultDatabase) private var database
    
    @FetchAll(Book.order(by: \.title))
    var books: [Book]
    
    @FetchAll(Author.order(by: \.name))
    var authors: [Author]
    
    @State private var showingAddBook = false
    @State private var showingAddAuthor = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Books (\(books.count))") {
                    ForEach(books) { book in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(book.title)
                                    .font(.headline)
                                Spacer()
                                Text("ID: \(book.id)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("by \(book.author)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Text("\(book.yearPublished)")
                                Spacer()
                                if book.isAvailable {
                                    Text("Available")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                } else {
                                    Text("Checked Out")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: deleteBooks)
                    
                    Button("Add Book") {
                        showingAddBook = true
                    }
                    .foregroundColor(.blue)
                }
                
                Section("Authors (\(authors.count))") {
                    ForEach(authors) { author in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(author.name)
                                    .font(.headline)
                                Spacer()
                                Text("ID: \(author.id)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                if let birthYear = author.birthYear {
                                    Text("Born: \(birthYear)")
                                }
                                if !author.nationality.isEmpty {
                                    Text("• \(author.nationality)")
                                }
                                Spacer()
                                if author.isActive {
                                    Text("Active")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: deleteAuthors)
                    
                    Button("Add Author") {
                        showingAddAuthor = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Debug", destination: DebugView())
                        .font(.caption)
                }
            }
            .alert("Add Book", isPresented: $showingAddBook) {
                Button("Add Sample") {
                    addSampleBook()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will add a sample book to the database.")
            }
            .alert("Add Author", isPresented: $showingAddAuthor) {
                Button("Add Sample") {
                    addSampleAuthor()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will add a sample author to the database.")
            }
        }
    }
    
    private func addSampleBook() {
        let sampleTitles = ["The Swift Programming Language", "Effective Swift", "iOS Development with SwiftUI", "Advanced iOS", "SwiftUI Mastery", "Core Data Guide"]
        let sampleAuthors = ["Apple Inc.", "Jon Reid", "Maria Garcia", "John Smith", "Sarah Wilson", "Mike Johnson"]
        let sampleYears = [2014, 2019, 2020, 2021, 2022, 2023, 2024]
        
        let title = sampleTitles.randomElement()! + " #\(Int.random(in: 1...999))"
        let author = sampleAuthors.randomElement()!
        let year = sampleYears.randomElement()!
        
        do {
            try database.write { db in
                try Book.insert {
                    Book.Draft(
                        title: title,
                        author: author,
                        yearPublished: year,
                        isAvailable: true,
                        createdAt: Date()
                    )
                }.execute(db)
            }
            print("Book added: \(title)")
        } catch {
            print("Error adding book: \(error)")
        }
    }
    
    private func addSampleAuthor() {
        let sampleNames = ["Apple Inc.", "Jon Reid", "Maria Garcia", "John Smith", "Sarah Wilson", "Mike Johnson", "Lisa Brown", "David Lee", "Emma Davis"]
        let sampleNationalities = ["USA", "UK", "Canada", "Spain", "Germany", "France", "Japan", "Australia"]
        let sampleBirthYears = [1960, 1970, 1975, 1980, 1985, 1988, 1990, 1995]
        
        let name = sampleNames.randomElement()! + " #\(Int.random(in: 1...999))"
        let nationality = sampleNationalities.randomElement()!
        let birthYear = sampleBirthYears.randomElement()
        
        do {
            try database.write { db in
                try Author.insert {
                    Author.Draft(
                        name: name,
                        birthYear: birthYear,
                        nationality: nationality,
                        isActive: true,
                        createdAt: Date()
                    )
                }.execute(db)
            }
            print("Author added: \(name)")
        } catch {
            print("Error adding author: \(error)")
        }
    }
    
    private func deleteBooks(atOffsets indices: IndexSet) {
        do {
            try database.write { db in
                let ids = indices.map { books[$0].id }
                try Book.where { ids.contains($0.id) }.delete().execute(db)
            }
        } catch {
            print("Error deleting books: \(error)")
        }
    }
    
    private func deleteAuthors(atOffsets indices: IndexSet) {
        do {
            try database.write { db in
                let ids = indices.map { authors[$0].id }
                try Author.where { ids.contains($0.id) }.delete().execute(db)
            }
        } catch {
            print("Error deleting authors: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
