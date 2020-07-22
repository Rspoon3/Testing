//
//  Team.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/9/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import UIKit
import CoreData

public class Team : NSManagedObject, Identifiable, NSSecureCoding {
    @NSManaged public var title: String
    @NSManaged public var createdAt: Date
    @NSManaged public var people: Set<Person>
    @NSManaged public var color: UIColor
    
    convenience init(title: String, context: NSManagedObjectContext) {
        self.init(context: context)
        self.title = title
        self.createdAt = Date()
        self.color = UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1.0)
    }

    static func getAllTeams() -> NSFetchRequest<Team> {
        let request : NSFetchRequest<Team> = Team.fetchRequest() as! NSFetchRequest<Team>
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return request
    }
    
    
    
    public static var supportsSecureCoding = true
    
    enum Keys: String {
      case title, createdAt, people, color
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey:  Keys.title.rawValue)
        aCoder.encode(createdAt, forKey: Keys.createdAt.rawValue)
        aCoder.encode(people, forKey: Keys.people.rawValue)
        aCoder.encode(color, forKey: Keys.color.rawValue)
    }
    
    required convenience public init?(coder aDecoder: NSCoder) {
        let managedObjectContext = PersistentStore.shared.context
        guard let entity = NSEntityDescription.entity(forEntityName: "Team", in: managedObjectContext) else {
            fatalError("Failed to decode Team")
        }
            
        self.init(entity: entity, insertInto: managedObjectContext)
        
        title = aDecoder.decodeObject(of: NSString.self, forKey: Keys.title.rawValue)! as String
        createdAt = aDecoder.decodeObject(of: NSDate.self, forKey: Keys.createdAt.rawValue)! as Date
        people = aDecoder.decodeObject(of: NSSet.self, forKey: Keys.people.rawValue)! as! Set<Person>
        color = aDecoder.decodeObject(of: UIColor.self, forKey: Keys.color.rawValue)!
    }
}



