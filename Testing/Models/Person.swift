//
//  Person.swift
//  Testing
//
//  Created by Richard Witherspoon on 6/25/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import Foundation
import CoreData

public class Person : NSManagedObject, Identifiable {
    @NSManaged public var name: String
    @NSManaged public var isFavorite: Bool
    @NSManaged public var team: Team
    @NSManaged public var createdAt: Date

    convenience init(name: String, team: Team, context: NSManagedObjectContext) {
        self.init(context: context)
        self.name = name
        self.isFavorite = false
        self.team = team
        self.createdAt = Date()
    }

    static func getAllPeople() -> NSFetchRequest<Person> {
        let request : NSFetchRequest<Person> = Person.fetchRequest() as! NSFetchRequest<Person>
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return request
    }
}
