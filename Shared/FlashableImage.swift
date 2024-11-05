//
//  FlashableImage.swift
//  Testing
//
//  Created by Ricky on 11/2/24.
//

import SwiftUI

struct FlashableImage: View {
    let index: Int
    let opacity: Double
    let showBorder: Bool
    
    var body: some View {
        Image("picture\(index)")
            .resizable()
            .scaledToFit()
            .cornerRadius(10)
            .opacity(opacity)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(showBorder ? Color.yellow : Color.clear, lineWidth: 10)
            )
            .animation(.spring(duration: 0.2), value: showBorder)

    }
}
