//
//  BlueSquare.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/15/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

struct BlueSquare : View{
    @Binding var backgroundColor: UIColor
    
    var body: some View{
        Color(backgroundColor)
            .edgesIgnoringSafeArea(.all)
            .onDrop(of: [UTI.color], delegate: ColorDropDelegate(color: $backgroundColor))
            .onDrag { NSItemProvider(object: self.backgroundColor as UIColor)}
            .frame(width: 200, height: 200)
            .cornerRadius(10)
    }
}

struct BlueSquare_Previews: PreviewProvider {
    static var previews: some View {
        BlueSquare(backgroundColor: .constant(.systemBlue))
    }
}
