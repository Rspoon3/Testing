import Combine
import GRDB
import SQLiteData
import StructuredQueries
import SwiftUI

// MARK: - Sectioned by genre

struct SectionedByGenreView: View {
    @Fetch(
        Book.where(\.isPinned)
            .order { $0.genre.asc() }
            .order { $0.title.asc() }
            .sectioned(by: \.genre),
        animation: .default
    )
    var sections: [FetchSection<String, Book>] = []

    // MARK: - Body

    var body: some View {
        List {
            ForEach(sections) { section in
                Section(section.id) {
                    ForEach(section.items) { book in
                        Text(book.title)
                    }
                }
            }
        }
        .navigationTitle("By Genre")
    }
}

// MARK: - Sectioned by pinned status

struct SectionedByPinnedView: View {
    @Fetch(
        Book.all
            .order { $0.isPinned.desc() }
            .order { $0.title.asc() }
            .sectioned(by: \.isPinned),
        animation: .default
    )
    var sections: [FetchSection<Bool, Book>] = []

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

// MARK: - Sectioned by release year

struct SectionedByYearView: View {
    @Fetch(
        Book.all
            .order { $0.releaseYear.desc() }
            .order { $0.title.asc() }
            .sectioned(by: \.releaseYear),
        animation: .default
    )
    var sections: [FetchSection<Int, Book>] = []

    // MARK: - Body

    var body: some View {
        List {
            ForEach(sections) { section in
                Section("\(section.id)") {
                    ForEach(section.items) { book in
                        BookRow(book: book)
                    }
                }
            }
        }
        .navigationTitle("By Year")
    }

    // MARK: - Private Views

    private func BookRow(book: Book) -> some View {
        VStack(alignment: .leading) {
            Text(book.title)
                .font(.headline)
            Text(book.releaseDate.formatted(.dateTime.year()))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Sectioned by author (join)

@Selection
nonisolated struct BookWithAuthor: Identifiable {
    var id: Book.ID
    var title: String
    var authorName: String
}

struct SectionedByAuthorRequest: FetchKeyRequest {
    func fetch(_ db: Database) throws -> [FetchSection<String, BookWithAuthor>] {
        try Book
            .join(Author.all) { $0.authorID.eq($1.id) }
            .order { _, authors in authors.name.asc() }
            .order { books, _ in books.title.asc() }
            .select { books, authors in
                BookWithAuthor.Columns(
                    id: books.id,
                    title: books.title,
                    authorName: authors.name
                )
            }
            .fetchCursor(db)
            .sectioned(by: \.authorName)
    }
}

struct SectionedByAuthorView: View {
    @Fetch(SectionedByAuthorRequest(), animation: .default)
    var sections: [FetchSection<String, BookWithAuthor>] = []

    // MARK: - Body

    var body: some View {
        List {
            ForEach(sections) { section in
                Section(section.id) {
                    ForEach(section.items) { row in
                        Text(row.title)
                    }
                }
            }
        }
        .navigationTitle("By Author")
    }
}

// MARK: - Manual fetch with .task

struct ManualSectionedView: View {
    @Dependency(\.defaultDatabase) private var database
    @State private var sections: [FetchSection<String, Book>] = []

    // MARK: - Body

    var body: some View {
        List {
            ForEach(sections) { section in
                Section(section.id) {
                    ForEach(section.items) { book in
                        Text(book.title)
                    }
                }
            }
        }
        .navigationTitle("Manual")
        .task { await loadData() }
        .onReceive(Timer.publish(every: 3, on: .main, in: .common).autoconnect()) { _ in
            guard AppConfig.enableTimers else { return }
            Task { await loadData() }
        }
    }

    // MARK: - Private Helpers

    private func loadData() async {
        await withErrorReporting {
            let result = try await database.read { db in
                try Book
                    .where(\.isPinned)
                    .order { $0.genre.asc() }
                    .order { $0.title.asc() }
                    .sectioned(by: \.genre)
                    .fetch(db)
            }
            withAnimation { sections = result }
        }
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

#Preview("By Author") {
    let _ = prepareDependencies {
        try! $0.bootstrapDatabase()
    }
    NavigationStack {
        SectionedByAuthorView()
    }
}
