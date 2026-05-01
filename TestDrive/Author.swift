//
//  Author.swift
//  TestDrive (iOS)
//
//  Created by Ricky Witherspoon on 8/9/25.
//

import Foundation
import SharingGRDB

@Table
struct Author: Codable, Hashable, Identifiable {
    let id: Int64
    let name: String
    let birthYear: Int?
    let nationality: String
    let isActive: Bool
    let createdAt: Date
}
