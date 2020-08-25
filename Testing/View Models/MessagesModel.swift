//
//  MessagesModel.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/25/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import Foundation
import CoreData

class MessagesModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate{
    @Published var messages = [Message]()
    private let messagesController: NSFetchedResultsController<Message>
    
    init(conversation: Conversation){
        messagesController = NSFetchedResultsController(fetchRequest: Message.getMessagesFor(conversation),
                                                     managedObjectContext: PersistentStore.shared.context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)
        super.init()
        messagesController.delegate = self
        
        do {
            try messagesController.performFetch()
            messages = messagesController.fetchedObjects ?? []
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let items = controller.fetchedObjects as? [Message]{
            messages = items
        }
    }
    
    func addMessage(to conversation: Conversation){
        PersistentStore.shared.persistentContainer.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            do {
                let tim = Person(context: context)
                tim.firstName = "Tim"
                tim.lastName = "Apple"
                tim.title = "CEO"
                
                let message = Message(context: context)
                message.id = 2
                message.message = "I Am Tim Apple"
                message.timeStamp = Date().timeIntervalSince1970
                message.person = tim
                
                conversation.messages.insert(message)
//                conversation.latestMessage = message
                
                if context.hasChanges {
                    try context.save()
                }
                
                // Free up some memory.
                context.reset()
            } catch{
                print("Message Model Error: \(error.localizedDescription)")
            }
        }
    }
}
