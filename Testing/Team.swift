//
//  Team.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/9/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import Foundation
import CoreData

public class Team : NSManagedObject, Identifiable {
    @NSManaged public var title: String
    @NSManaged public var createdAt: Date
    @NSManaged public var people: Set<Person>
    
    convenience init(title: String, context: NSManagedObjectContext) {
        self.init(context: context)
        self.title = title
        self.createdAt = Date()
    }

    static func getAllTeams() -> NSFetchRequest<Team> {
        let request : NSFetchRequest<Team> = Team.fetchRequest() as! NSFetchRequest<Team>
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return request
    }
}
