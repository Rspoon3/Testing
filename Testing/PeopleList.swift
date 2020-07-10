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
                HStack{
                    Text(person.name)
                        .font(.largeTitle)
                        .contextMenu{
                            Button("Toggle Favorite"){
                                person.isFavorite.toggle()
                                team.objectWillChange.send()
                                try? moc.save()
                            }
                        }
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundColor(person.isFavorite ? Color.yellow : .gray)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("test")
    }
}

struct PeopleList_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return PeopleList(team: Team(title: "Soccer", context: context))
    }
}
