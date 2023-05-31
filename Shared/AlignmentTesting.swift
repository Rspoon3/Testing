//
//  AlignmentTesting.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 5/28/23.
//

import SwiftUI

struct AlignmentTesting: View {
    var body: some View {
        ZStack(alignment: .myAlignment) {
            Text("Hello, World! This is a lot of text that I need to wrap around. To the next line so that its all visible. I would like it to not get cut off but it appears to be.")
                .foregroundColor(Color.green)
                .frame(height: 100)
                .alignmentGuide(HorizontalAlignment.myAlignment){
                    d in d[.leading]
                }
                .border(Color.blue)
            
            Rectangle()
                .foregroundColor(Color.red)
                .frame(width: 100, height: 100)
                .alignmentGuide(HorizontalAlignment.myAlignment) { d in d[HorizontalAlignment.trailing]
                }
        }
    }
}

extension HorizontalAlignment {
    enum MyHorizontal: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            d[HorizontalAlignment.trailing]
        }
    }
    
    static let myAlignment =  HorizontalAlignment(MyHorizontal.self)
}

extension Alignment {
    static let myAlignment = Alignment(
        horizontal: .myAlignment,
        vertical: .myAlignment
    )
}


struct AlignmentTesting_Previews: PreviewProvider {
    static var previews: some View {
        AlignmentTesting()
    }
}
