//
//  CardView.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import SwiftUI

struct CardView: View {
    var card: Card
    let width: CGFloat
    
    var body: some View {
        Image("numbers\(card.imageNumber)")
            .resizable()
            .scaledToFill()
            .frame(width: width, height: width * 1.5)
            .blur(radius: 2)
            .overlay {
                ZStack {
                    Color.black.opacity(0.6)
                    Text("\(card.number)")
                        .font(.system(size: 160, weight: .bold))
                        .foregroundStyle(card.color.gradient)
                        .shadow(radius: 5)
                }
            }
            .cornerRadius(20)
    }
}
