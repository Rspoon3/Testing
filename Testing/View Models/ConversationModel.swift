//
//  ConversationModel.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/25/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import Foundation
import CoreData

class ConversationModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate{
    @Published var conversations = [Conversation]()
    private let conversationsController: NSFetchedResultsController<Conversation>
    
    override init(){
        conversationsController = NSFetchedResultsController(fetchRequest: Conversation.getAllConversations(),
                                                     managedObjectContext: PersistentStore.shared.context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)
        super.init()
        conversationsController.delegate = self
        
        do {
            try conversationsController.performFetch()
            conversations = conversationsController.fetchedObjects ?? []
            createConversations()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    private func createConversations(){
        let context      = PersistentStore.shared.context
        let conversation = Conversation(context: context)
        let ricky        = Person(context: context)
        let message      = Message(context: context)
        
        ricky.firstName = "Ricky"
        ricky.lastName = "W"
        ricky.title = "iOS Dev"
        
        message.id = 1
        message.message = "Testing 123"
        message.timeStamp = Date().timeIntervalSince1970
        message.person = ricky
        
        conversation.myDescription = "This is a conversation"
        conversation.id = 1
        conversation.activeParticipants.insert(ricky)
        conversation.latestMessage = message
        conversation.messages.insert(message)
        
        PersistentStore.shared.saveContext()
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let items = controller.fetchedObjects as? [Conversation]{
            conversations = items
        }
    }
}
