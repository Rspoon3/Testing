//
//  Person.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//


import Foundation

struct Person: Identifiable, Equatable {
    let id: UUID
    var name: String
    var age: Int

    init(id: UUID = UUID(), name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }
}