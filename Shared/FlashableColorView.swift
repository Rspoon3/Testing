//
//  FlashableColorView.swift
//  Testing
//
//  Created by Ricky on 11/2/24.
//

import SwiftUI

struct FlashableColorView: View {
    let colorType: FlashableColor
    let opacity: Double
    @Binding var showBorder: Bool
    
    var body: some View {
        Image("picture\(colorType.rawValue)")
            .resizable()
            .scaledToFit()
            .cornerRadius(10)
            .opacity(opacity)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(showBorder ? Color.yellow : Color.clear, lineWidth: 10)
            )
            .animation(.linear(duration: 0.3), value: showBorder)
    }
}
