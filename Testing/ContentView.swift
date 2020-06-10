//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct ContentView : View {
    @State var backgroundColor = Color.blue
    
    var body : some View{
        backgroundColor
            .edgesIgnoringSafeArea(.all)
            .onDrop(of: [UTI.data], delegate: ColorDropDelegate(color: $backgroundColor))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
