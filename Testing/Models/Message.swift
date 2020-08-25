//
//  Message.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/24/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import CoreData


public class Message : NSManagedObject, Identifiable {
    @NSManaged public var id           : Int
    @NSManaged public var message      : String
    @NSManaged public var timeStamp    : Double
    @NSManaged public var person       : Person
    @NSManaged public var conversation : Conversation
    @NSManaged public var latestConversation : Conversation
    
    static func getMessagesFor(_ conversation: Conversation) -> NSFetchRequest<Message> {
        let request : NSFetchRequest<Message> = Message.fetchRequest() as! NSFetchRequest<Message>
        request.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
        request.predicate = NSPredicate(format: "conversation == %@", conversation)
        return request
    }
    
    static func getAllMessages() -> NSFetchRequest<Message> {
        let request : NSFetchRequest<Message> = Message.fetchRequest() as! NSFetchRequest<Message>
        request.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: true)]
        return request
    }
}
