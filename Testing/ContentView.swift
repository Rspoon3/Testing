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
    
    var body : some View{
        Color(backgroundColor)
            .edgesIgnoringSafeArea(.all)
            .onDrop(of: [UTI.color], delegate: ColorDropDelegate(color: $backgroundColor))
            .onDrag { NSItemProvider(object: self.backgroundColor as UIColor)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
