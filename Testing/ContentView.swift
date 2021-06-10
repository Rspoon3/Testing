//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    @State var textColor = UIColor.black
    
    var sidebar: some View{
        List{
            Text("Accept Drop Here")
                .foregroundColor(Color(textColor))
        }
        .onDrop(of: [UTI.color], delegate: ColorDropDelegate(color: $textColor))
        .listStyle(.sidebar)
        .navigationTitle("Drag & Drop")
    }
    
    var body : some View{
        NavigationView{
            sidebar
            BlueSquare()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
