import Dependencies
import IssueReporting
import SQLiteData
import SwiftUI

struct ContentView: View {
    @Dependency(\.defaultDatabase) private var database
    @State private var timer: Timer?

    private let randomBooks: [(String, String, Int, Date)] = [
        ("Refactoring", "Software", 448, makeDate(1999, 7, 8)),
        ("Domain-Driven Design", "Software", 560, makeDate(2008, 8, 30)),
        ("The Art of Computer Programming", "Computer Science", 672, makeDate(2017, 1, 1)),
        ("Code Complete", "Software", 960, makeDate(1999, 5, 1)),
        ("Peopleware", "Management", 264, makeDate(2008, 2, 1)),
        ("Working Effectively with Legacy Code", "Software", 456, makeDate(2017, 9, 22)),
        ("Introduction to Algorithms", "Computer Science", 1312, makeDate(1999, 7, 1)),
        ("Compilers: Principles, Techniques, and Tools", "Computer Science", 1009, makeDate(2017, 1, 1)),
        ("Team Topologies", "Management", 240, makeDate(2019, 9, 17)),
    ]

    // MARK: - Body

    var body: some View {
        TabView {
            Tab("Genre", systemImage: "books.vertical") {
                NavigationStack {
                    SectionedByGenreView()
                }
            }
            Tab("Pinned", systemImage: "pin") {
                NavigationStack {
                    SectionedByPinnedView()
                }
            }
            Tab("Year", systemImage: "calendar") {
                NavigationStack {
                    SectionedByYearView()
                }
            }
            Tab("Author", systemImage: "person.2") {
                NavigationStack {
                    SectionedByAuthorView()
                }
            }
            Tab("Manual", systemImage: "arrow.down.circle") {
                NavigationStack {
                    ManualSectionedView()
                }
            }
        }
        .onAppear { if AppConfig.enableTimers { startTimer() } }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Private Helpers

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            let book = randomBooks.randomElement()!
            withErrorReporting {
                try database.write { db in
                    let authors = try Author.fetchAll(db)
                    guard let author = authors.randomElement() else { return }
                    try Book.insert {
                        Book.Draft(
                            authorID: author.id,
                            title: book.0,
                            genre: book.1,
                            pageCount: book.2,
                            isPinned: Bool.random(),
                            releaseDate: book.3
                        )
                    }
                    .execute(db)
                }
            }
        }
    }
}

nonisolated private func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
    DateComponents(calendar: .current, year: year, month: month, day: day).date!
}

#Preview {
    let _ = prepareDependencies {
        try! $0.bootstrapDatabase()
    }
    ContentView()
}
