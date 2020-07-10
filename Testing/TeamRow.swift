//
//  TeamRow.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/10/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct TeamRow: View{
    var latestPersonFetchRequest: FetchRequest<Person>
    let team: Team
    
    init(_ team: Team) {
        self.team = team
        latestPersonFetchRequest = FetchRequest<Person>(
            entity: Person.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Person.createdAt, ascending: false)],
            predicate: NSPredicate(format: "team == %@", self.team))
    }
    
    var body: some View{
        VStack(alignment: .leading){
            Text(team.title)
                .font(.title)
            if let person = latestPersonFetchRequest.wrappedValue.first{
                Text(person.name)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TeamRow_Previews: PreviewProvider {
    static var previews: some View {
        TeamRow(Team(title: "Test", context: .init(concurrencyType: .mainQueueConcurrencyType)))
    }
}
