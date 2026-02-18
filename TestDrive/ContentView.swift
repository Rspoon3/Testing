//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import Dependencies
import SQLiteData
import SwiftUI

struct ContentView: View {
    @FetchAll(Book.order(by: \.title)) var books

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List(books) { book in
                BookRow(book: book)
            }
            .navigationTitle("Books")
        }
    }

    // MARK: - Private Views

    private func BookRow(book: Book) -> some View {
        VStack(alignment: .leading) {
            Text(book.title)
                .font(.headline)
            Text(book.author)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(book.pageCount) pages")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        try! $0.bootstrapDatabase()
    }
    ContentView()
}
