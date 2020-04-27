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
    @State var selection = 0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let people = [
        Person(name: "Ricky", age: 24),
        Person(name: "Kaitlin", age: 21),
        Person(name: "Nick", age: 20),
        Person(name: "Sandy", age: 19),
        Person(name: "Jeniffer", age: 26),
        Person(name: "Rodney", age: 30),
        Person(name: "George", age: 17),
    ]
    
    init() {
        UITableView.appearance().tableFooterView = UIView()
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().allowsSelection = false
        UITableViewCell.appearance().selectionStyle = .none
    }
    
    
    var body : some View{
        GeometryReader { geo in
            NavigationView{
                List{
                    ForEach(0..<self.people.count) { i in
                        VStack{
                            NavigationLink(destination: DetailsView(person: self.people[i], selection: self.$selection, num: i)) {
                                Text("Check out \(self.people[i].name)")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                            .background(Color.purple.opacity(i == self.selection  && self.horizontalSizeClass != .compact ? 0.5 : 0.25))
                        .cornerRadius(10)
                        .padding()
                        }
                    }.navigationBarTitle("People")
                    
                }
                DetailsView(person: self.people.first!, selection: self.$selection, num: nil)
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
            .padding(.leading, geo.size.height > geo.size.width ? 1 : 0)
        }
    }
}

struct DetailsView : View {
    let person: Person
    @Binding var selection: Int
    let num: Int?
    
    var body : some View{
        VStack{
            NavigationLink(destination: Rectangle().frame(width: 200, height: 150).foregroundColor(Color.blue.opacity(0.25)).cornerRadius(6)) {
            Text(person.name)
                .font(.title)
            Text(person.age.description)
                .foregroundColor(.gray)
            }
        }.onAppear{
            if let num = self.num{
                self.selection = num
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
