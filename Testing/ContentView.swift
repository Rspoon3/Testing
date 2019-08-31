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

struct ID : Identifiable{
    var id : Int
}

struct ContentView: View {
    
    var body: some View {
        ScrollView{
            MyList()
            MyList()
            MyList()
        }
    }
}

struct MyList : View {
    let ids = [ID(id: 1),ID(id: 2),ID(id: 3),ID(id: 4),ID(id: 5),ID(id: 6)]
    
    var body: some View{
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 100) {
                ForEach(ids) {id in
                    NavigationLink(
                        destination: Text("daf")
                    ){
                        MyButton()
                    }
                }
            }
        }.frame(height: 50)
    }
}

struct MyButton : View {
    @State var isYellow = true
    
    var body : some View{
        Image(systemName: "star.fill")
            .font(.title)
            .foregroundColor(isYellow ? .yellow : .blue)
            .frame(width: 50, height: 50)
    }
}


#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
