//
//  TeamList.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/9/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct TeamList: View {
    @StateObject var model = TeamModel()
    
    var body: some View {
        VStack{
            TextField("", text: $model.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            List(model.teams){ team in
                NavigationLink(destination: PeopleList(team: team), label: {
                    TeamRow(team)
                })
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        model.addTeam()
                    }, label: {
                        Image(systemName: "plus")
                    }).disabled(model.title.isEmpty)
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
