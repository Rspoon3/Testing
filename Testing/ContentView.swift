//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    @State var backgroundColor = UIColor.systemBlue
    @State var textColor = UIColor.black
    
    var sidebar: some View{
        List{
            ForEach(0..<10){ _ in
                NavigationLink(
                    destination: BlueSquare(backgroundColor: $backgroundColor),
                    label: {
                        Text("Testing")
                            .foregroundColor(Color(textColor))
                            .onDrop(of: [UTI.color], delegate: ColorDropDelegate(color: $textColor))
                    })
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Drag & Drop")
    }
    
    var body : some View{
        NavigationView{
            sidebar
            BlueSquare(backgroundColor: $backgroundColor)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
