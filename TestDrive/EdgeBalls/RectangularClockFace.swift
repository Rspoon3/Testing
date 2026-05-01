//
//  RectangularClockFace.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 8/20/25.
//

import SwiftUI

struct RectangularClockFace: View {
    let rect: CGRect
    let showPath: Bool
    let cornerRadius: CGFloat = 50
    private let pathHelper: RoundedRectanglePath
    
    // MARK: - Initializer
    
    init(rect: CGRect, showPath: Bool) {
        self.rect = rect
        self.showPath = showPath
        self.pathHelper = RoundedRectanglePath(rect: rect, cornerRadius: cornerRadius)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if showPath {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
            
            ForEach(0..<12) { hour in
                let position = pathHelper.hourPosition(for: hour == 0 ? 12 : hour)
                
                Text("\(hour == 0 ? 12 : hour)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .position(position)
            }
        }
    }
}
