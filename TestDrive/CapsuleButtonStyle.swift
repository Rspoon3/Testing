//
//  CapsuleButtonStyle.swift
//  Testing
//
//  Created by Ricky on 11/4/24.
//

import SwiftUI

struct CapsuleButtonStyle: ButtonStyle {
    var backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 30, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .padding(.vertical)
            .frame(width: 300)
            .background(
                Capsule()
                    .fill(backgroundColor)
                    .background(
                        Capsule()
                            .fill(backgroundColor)
                            .overlay(
                                Capsule()
                                    .fill(Color.black.opacity(0.2))
                            )
                            .offset(y: 10)
                    )
            )
            .padding(.bottom, 10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Scale effect for pressed state
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed) // Smooth scaling animation
    }
}
