//
//  PersonRow.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/10/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct PersonRow: View {
    @Environment(\.managedObjectContext) var moc
    let person: Person
    
    var body: some View {
        HStack{
            Text(person.name)
                .font(.largeTitle)
                .contextMenu{
                    Button("Toggle Favorite"){
                        person.isFavorite.toggle()
                        person.team.objectWillChange.send()
                        try? moc.save()
                    }
                }
            Spacer()
            Image(systemName: "star.fill")
                .foregroundColor(person.isFavorite ? Color.yellow : .gray)
        }
    }
}

struct PersonRow_Previews: PreviewProvider {
    static var previews: some View {
        PersonRow(person: Person(name: "Ricky", team: Team(title: "Soccer", context: .init(concurrencyType: .mainQueueConcurrencyType)), context: .init(concurrencyType: .mainQueueConcurrencyType)))
    }
}
