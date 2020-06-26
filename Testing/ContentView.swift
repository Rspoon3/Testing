//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(fetchRequest: Person.getAllPeople()) var people : FetchedResults<Person>
    @State var name = String()
    
    func addPerson(){
        let _ = Person(name: name, context: moc)
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
                }
            }.padding()
            
            List(people){ person in
                HStack{
                    Text(person.name)
                        .font(.largeTitle)
                        .contextMenu{
                            Button("Toggle Favorite"){
                                person.isFavorite.toggle()
                                try? moc.save()
                            }
                        }
                    Spacer()
                    Image(systemName: "star.fill")
                        .foregroundColor(person.isFavorite ? Color.yellow : .gray)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
