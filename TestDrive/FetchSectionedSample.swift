import Combine
import SQLiteData
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
