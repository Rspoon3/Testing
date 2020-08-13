//
//  TeamModel.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/13/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import CoreData

class TeamModel:NSObject, ObservableObject{
    @Published var teams = [Team]()
    @Published var title = String()
    
    private let teamsController: NSFetchedResultsController<Team>
    
    override init(){
        teamsController = NSFetchedResultsController(fetchRequest: Team.getAllTeams(),
                                                     managedObjectContext: PersistentStore.shared.context,
                                                     sectionNameKeyPath: nil,
                                                     cacheName: nil)
        super.init()

        teamsController.delegate = self
        
        do {
            try teamsController.performFetch()
            teams = teamsController.fetchedObjects ?? []
        } catch {
            print("failed to fetch items!")
        }
    }
    
    func addTeam(){
        let _ = Team(title: title, context: PersistentStore.shared.context)
        PersistentStore.shared.saveContext()
        title.removeAll()
    }
}


extension TeamModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let items = controller.fetchedObjects as? [Team]{
            teams = items
        }
    }
}
