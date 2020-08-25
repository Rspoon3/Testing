//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/21/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        NavigationView{
            ConversationsView()
            Text("Select a conversation")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}








