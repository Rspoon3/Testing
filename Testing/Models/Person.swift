//
//  Person.swift
//  Testing
//
//  Created by Richard Witherspoon on 6/25/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import Foundation
import CoreData


public class Person: NSManagedObject, Identifiable {
    @NSManaged public var firstName: String
    @NSManaged public var lastName: String
    @NSManaged public var title: String
    @NSManaged public var conversations: Set<Conversation>
    @NSManaged public var messages: Set<Message>
    
    var fullName : String{
        "\(firstName) \(lastName)"
    }
    
    static func getAllPeopleWith(title: String) -> NSFetchRequest<Person> {
        let request : NSFetchRequest<Person> = Person.fetchRequest() as! NSFetchRequest<Person>
        request.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: false)]
        request.predicate = NSPredicate(format: "title == %@", title)
        return request
    }
    
    static func getAllPeople() -> NSFetchRequest<Person> {
        let request : NSFetchRequest<Person> = Person.fetchRequest() as! NSFetchRequest<Person>
        request.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: false)]
        return request
    }
}
