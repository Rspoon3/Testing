//
//  PersonStore.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/18/25.
//


import Foundation
import Combine

final class PersonStore: InMemoryStore<[Person]> {
    static let shared = PersonStore()

    private init() {
        super.init(initialValue: [])
    }

    func add(_ person: Person) {
        let people = value + [person]
        update(people)
    }

    func remove(id: UUID) {
//        mutate { people in
//            people.removeAll { $0.id == id }
//        }
    }

    func update(_ person: Person) {
//        mutate { people in
//            people = people.map {
//                $0.id == person.id ? person : $0
//            }
//        }
    }
}
