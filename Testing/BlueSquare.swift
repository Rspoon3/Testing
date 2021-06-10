//
//  BlueSquare.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/15/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct BlueSquare : View{
    
    var body: some View{
        Color.blue
            .edgesIgnoringSafeArea(.all)
            .onDrag { NSItemProvider(object: UIColor.systemBlue)}
            .frame(width: 200, height: 200)
            .cornerRadius(10)
    }
}

struct BlueSquare_Previews: PreviewProvider {
    static var previews: some View {
        BlueSquare()
    }
}
