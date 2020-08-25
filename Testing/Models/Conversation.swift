//
//  Conversation.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/24/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import CoreData

public class Conversation : NSManagedObject, Identifiable{
    @NSManaged public var activeParticipants   : Set<Person>
    @NSManaged public var myDescription        : String
    @NSManaged public var id                   : Int
    @NSManaged public var messages             : Set<Message>
    @NSManaged public var latestMessage        : Message
    
    static func getAllConversations() -> NSFetchRequest<Conversation> {
        let request : NSFetchRequest<Conversation> = Conversation.fetchRequest() as! NSFetchRequest<Conversation>
        request.sortDescriptors = [NSSortDescriptor(key: "latestMessage.timeStamp", ascending: false)]
        return request
    }
}
