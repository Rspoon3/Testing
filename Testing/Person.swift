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
    
    convenience init(name: String, context: NSManagedObjectContext) {
        self.init(context: context)
        self.name = name
        self.isFavorite = false
    }

    static func getAllPeople() -> NSFetchRequest<Person> {
        let request : NSFetchRequest<Person> = Person.fetchRequest() as! NSFetchRequest<Person>
        request.sortDescriptors = []
        return request
    }
}
