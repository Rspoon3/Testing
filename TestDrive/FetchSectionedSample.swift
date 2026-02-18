import SQLiteData
import SwiftUI

// MARK: - Sectioned by genre

struct SectionedByGenreView: View {
    @FetchSectioned(
        Book.where(\.isPinned),
        sectionIdentifier: \.genre,
        sortDescriptors: [
            SortDescriptor(\.genre, order: .forward),
            SortDescriptor(\.title, order: .forward),
        ],
        animation: .default
    )
    var sections: [FetchSection<String, Book>]

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
    @FetchSectioned(
        Book.all,
        sectionIdentifier: \.isPinned,
        sortDescriptors: [
            SortDescriptor(\.isPinned, order: .reverse),
            SortDescriptor(\.title, order: .forward),
        ],
        animation: .default
    )
    var sections: [FetchSection<Bool, Book>]

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
