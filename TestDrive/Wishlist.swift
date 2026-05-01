//
//  Wishlist.swift
//  Testing
//
//  Created by Ricky on 12/21/24.
//
import Foundation


struct Wishlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var urls: [URL]
    
    init(id: UUID = UUID(), name: String, urls: [URL] = []) {
        self.id = id
        self.name = name
        self.urls = urls
    }
}
