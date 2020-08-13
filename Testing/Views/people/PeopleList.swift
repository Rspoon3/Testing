//
//  PeopleList.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct PeopleList : View {
    @ObservedObject var team: Team
    @Environment(\.managedObjectContext) var moc
    @State var name = String()
    
    func addPerson(){
        let _ = Person(name: name,team: team, context: moc)
        try? moc.save()
        name.removeAll()
    }
    
    var body : some View{
        VStack{
            HStack{
                TextField("", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Spacer()
                Button("Add Person"){
                    addPerson()
                }.disabled(name.isEmpty)
            }.padding()
            
            List(team.people.sorted(by: {$0.name < $1.name})){ person in
                NavigationLink(destination: Text("go"), label: {
                    PersonRow(person: person)
                        .contextMenu{
                            Text("Test")
                        }
                })
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("test")
    }
}

struct PeopleList_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistentStore.shared.context
        return PeopleList(team: Team(title: "Soccer", context: context))
            .environment(\.managedObjectContext, context)
    }
}
