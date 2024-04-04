//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestingApp: App {
    var body: some Scene {
        WindowGroup {
//            ContentView()
            ContentTest()
        }
    }
}


struct ContentTest: View {
    private let cellSize: CGFloat = 65
    private let leadingPadding: CGFloat = 16
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ScrollView(.horizontal) {
                    HStack(spacing: calculateSpacing(width: geo.size.width)) {
                        ForEach(0..<20) { i in
                            Circle()
                                .frame(width: cellSize, height: cellSize)
                                .foregroundColor(i.isMultiple(of: 2) ? .blue : .green)
                        }
                    }
                    .padding(.horizontal, leadingPadding)
                }
                Text(geo.size.width.formatted())
            }
        }
    }
    
    func calculateSpacing(width: CGFloat) -> CGFloat {
        let halfSize = cellSize / CGFloat(2)
        let availableWidth = width - leadingPadding
        let visibleItemsNumber = availableWidth / cellSize
        let fullyVisibleItemsCount = CGFloat(Int(visibleItemsNumber))
        let fullVisibleItemsSize = cellSize * fullyVisibleItemsCount
        let remainingSpace = availableWidth - fullVisibleItemsSize
        let something = remainingSpace - halfSize
        let spacing = something / fullyVisibleItemsCount
        
        let desiredSpacing: CGFloat
        let minSpacing: CGFloat = 6
        let maxSpacing: CGFloat = 16
        
        if spacing < minSpacing {
            desiredSpacing = minSpacing
        } else if spacing > maxSpacing {
            desiredSpacing = maxSpacing
        } else {
            desiredSpacing = spacing
        }
        
        print(spacing, desiredSpacing, visibleItemsNumber)

        return desiredSpacing
    }
}


#Preview {
    ContentTest()
}

//32.5, 50%
///393 - 16 = 377
///377 / 65 = 5.8 -> 65 *5 = 325 -> 377 - 325 =  52 (px of last one)
/// 52 - 32.5 = 19.5 -> 19.5 / 5 =
