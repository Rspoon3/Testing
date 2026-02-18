import Foundation
import SQLiteData
import SwiftUI

// MARK: - Sectioned by genre

struct SectionedByGenreRequest: FetchKeyRequest {
    var sortDescriptors: [Foundation.SortDescriptor<Book>] = [
        Foundation.SortDescriptor(\.genre, order: .forward),
        Foundation.SortDescriptor(\.title, order: .forward),
    ]

    func fetch(_ db: Database) throws -> [FetchSection<String, Book>] {
        let books = try Book.all.fetchAll(db).sorted(using: sortDescriptors)
        return FetchSection.sections(from: books, by: \.genre)
    }
}

struct SectionedByGenreView: View {
    @Fetch(SectionedByGenreRequest(), animation: .default) var sections: [FetchSection<String, Book>] = []

    // MARK: - Body

    var body: some View {
        List {
            ForEach(sections) { section in
                Section(section.id) {
                    ForEach(section.items) { book in
                        BookRow(book: book)
                    }
                }
            }
        }
        .navigationTitle("By Genre")
    }

    // MARK: - Private Views

    private func BookRow(book: Book) -> some View {
        VStack(alignment: .leading) {
            Text(book.title)
                .font(.headline)
            Text(book.author)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Sectioned by pinned status

struct SectionedByPinnedRequest: FetchKeyRequest {
    func fetch(_ db: Database) throws -> [FetchSection<Bool, Book>] {
        let books = try Book.all
            .order { $0.isPinned.desc() }
            .order(by: \.title)
            .fetchAll(db)
        return FetchSection.sections(from: books, by: \.isPinned)
    }
}

struct SectionedByPinnedView: View {
    @Fetch(SectionedByPinnedRequest(), animation: .default) var sections: [FetchSection<Bool, Book>] = []

    // MARK: - Body

    var body: some View {
        List {
            ForEach(sections) { section in
                Section(section.id ? "Pinned" : "All Books") {
                    ForEach(section.items) { book in
                        Text(book.title)
                    }
                }
            }
        }
        .navigationTitle("Pinned")
    }
}

// MARK: - Previews

#Preview("By Genre") {
    let _ = prepareDependencies {
        try! $0.bootstrapDatabase()
    }
    NavigationStack {
        SectionedByGenreView()
    }
}

#Preview("By Pinned") {
    let _ = prepareDependencies {
        try! $0.bootstrapDatabase()
    }
    NavigationStack {
        SectionedByPinnedView()
    }
}
