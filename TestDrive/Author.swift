import Foundation
import StructuredQueries

@Table
nonisolated struct Author: Identifiable {
    let id: UUID
    var name: String
}
