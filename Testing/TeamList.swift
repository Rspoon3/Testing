//
//  TeamList.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/9/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct TeamList: View {
    @FetchRequest(fetchRequest: Team.getAllTeams()) var teams : FetchedResults<Team>
    @State var title = String()
    @Environment(\.managedObjectContext) var moc

    func addTeam(){
        let _ = Team(title: title, context: moc)
        try? moc.save()
        title.removeAll()
    }
    
    var body: some View {
        VStack{
            TextField("", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            List(teams){ team in
                NavigationLink(destination: PeopleList(team: team), label: {
                    TeamRow(team)
                })
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        addTeam()
                    }, label: {
                        Image(systemName: "plus")
                    }).disabled(title.isEmpty)
                }
            }
        }.navigationTitle("Teams")
    }
}

struct TeamList_Previews: PreviewProvider {
    static var previews: some View {
        TeamList()
    }
}
