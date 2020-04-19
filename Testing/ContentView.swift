//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct Person: Identifiable{
    let id = UUID()
    let name: String
    let age : Int
}

struct ContentView : View {
    let people = [
        Person(name: "Ricky", age: 24),
        Person(name: "Kaitlin", age: 21),
        Person(name: "Nick", age: 20),
        Person(name: "Sandy", age: 19),
        Person(name: "Jeniffer", age: 26),
        Person(name: "Rodney", age: 30),
        Person(name: "George", age: 17),
    ]
    
    var body : some View{
        NavigationView{
            List{
                ForEach(people){ person in
                    NavigationLink(destination: DetailsView(person: person), isActive: .constant(true)) {
                        Text("Check out \(person.name)")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.25))
                        .cornerRadius(10)
                    .padding()
                }.navigationBarTitle("People")
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .padding(.all,0.5)
    }
}

struct DetailsView : View {
    let person: Person
    
    var body : some View{
        VStack{
            Text(person.name)
                .font(.title)
            Text(person.age.description)
                .foregroundColor(.gray)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
