//
//  TestingWidgetEntryView.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 7/17/23.
//

import Foundation
import SwiftUI
import WidgetKit

struct TestingWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Image("personalRecord")
            
            ZStack(alignment: .top) {
                Triangle()
                    .frame(height: 50)
                    .foregroundColor(.blue)
                
                Text("12,495")
                    .font(.headline)
                    .padding(.all, 5)
                    .background(
                        ZStack {
                            Capsule()
                                .foregroundColor(.blue )
                                .padding(.all, -2)
                            Capsule()
                                .foregroundColor(.white)
                        }
                    )
                    .alignmentGuide(HorizontalAlignment.center) { d in
                        d[.leading]
                    }
                    .offset(x: -7)
                
            }
                                .rotationEffect(.degrees(-10))
        }
    }
}


struct TestingWidget_Previews: PreviewProvider {
    static var previews: some View {
        TestingWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - 55, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - 24, y: rect.minY + 28))
        return path
    }
}
