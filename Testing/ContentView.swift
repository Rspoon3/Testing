//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 8/27/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

import SwiftUI
import Combine

struct Person : Identifiable{
    var id : Int
    var name : String
}

struct ContentView: View {
    let people = [
        Person(id: 1, name: "Ricky"),
        Person(id: 2, name: "Dani"),
        Person(id: 3, name: "Mark"),
        Person(id: 4, name: "Kailin"),
        Person(id: 5, name: "James"),
        Person(id: 5, name: "Jenna")
    ]
    
    var body: some View {
        NavigationView{
            ScrollView{
                ZStack {
                    Color.init(UIColor.red)
                    VStack {
                        ForEach(people, id: \.id) { person in
                            Text(person.name)
                                .frame(width: 300, height: 400)
                                .background(Color.blue)
                                .padding()
                        }
                    }
                }
            }.navigationBarTitle("Home")
        }
    }
    
    init(){
        UINavigationBar.appearance().backgroundColor = .red
    }
}




#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
