import Foundation
import SharingGRDB

@Table
struct Book: Codable, Hashable, Identifiable {
    let id: Int64
    let title: String
    let author: String
    let yearPublished: Int
    let isAvailable: Bool
    let createdAt: Date
}
