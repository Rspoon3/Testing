import Dependencies
import IssueReporting
import SQLiteData
import SwiftUI

struct ContentView: View {
    @Dependency(\.defaultDatabase) private var database
    @State private var timer: Timer?

    private let randomBooks: [(String, String, String, Int)] = [
        ("Refactoring", "Martin Fowler", "Software", 448),
        ("Domain-Driven Design", "Eric Evans", "Software", 560),
        ("The Art of Computer Programming", "Donald Knuth", "Computer Science", 672),
        ("Code Complete", "Steve McConnell", "Software", 960),
        ("Peopleware", "Tom DeMarco & Timothy Lister", "Management", 264),
        ("Working Effectively with Legacy Code", "Michael Feathers", "Software", 456),
        ("Introduction to Algorithms", "Thomas Cormen", "Computer Science", 1312),
        ("The Phoenix Project", "Gene Kim", "Management", 432),
        ("Compilers: Principles, Techniques, and Tools", "Alfred Aho", "Computer Science", 1009),
        ("Team Topologies", "Matthew Skelton", "Management", 240),
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
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Private Helpers

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            let book = randomBooks.randomElement()!
            withErrorReporting {
                try database.write { db in
                    try Book.insert {
                        Book.Draft(
                            title: book.0,
                            author: book.1,
                            genre: book.2,
                            pageCount: book.3,
                            isPinned: Bool.random()
                        )
                    }
                    .execute(db)
                }
            }
        }
    }
}

#Preview {
    let _ = prepareDependencies {
        try! $0.bootstrapDatabase()
    }
    ContentView()
}
