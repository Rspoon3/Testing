//
//  PersistentStore.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/21/20.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI
import CoreData

class PersistentStore: ObservableObject {
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    static let shared = PersistentStore()
    private init() {}
    
    // MARK: - Core Data stack
    let persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentCloudKitContainer(name: "CoreDataTesting")
        
        // Enable remote notifications
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
            
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    
    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
