//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/21/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @FetchRequest(fetchRequest: Team.getAllTeams()) var teams : FetchedResults<Team>
    
    var body: some View {
        NavigationView{
            TeamList()
            if teams.first != nil{
                PeopleList(team: teams.first!)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
