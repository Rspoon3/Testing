//
//  DeliveryOptions.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 2/24/21.
//

import SwiftUI

struct DeliveryOptions: View {
    let circleSize: CGFloat = 20
    let spacing: CGFloat = 10
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10){
            Text("Choose your delivery option:")
                .font(.headline)
            HStack(alignment: .top){
                Circle()
                    .frame(width: circleSize, height: circleSize)
                    .foregroundColor(Color(.systemGray))
                    .overlay(Circle()
                                .strokeBorder()
                                .foregroundColor(.secondary)
                                .overlay(Circle()
                                            .frame(width: circleSize / 2, height: circleSize / 2)
                                            .foregroundColor(.white))
                    )
                    .overlay(Circle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 2))
                                .foregroundColor(Color(.systemTeal))
                             )
                VStack(alignment: .leading, spacing: spacing){
                    Text("Today, by end of day")
                        .foregroundColor(.darkGreen)
                    Text("$5.99")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .strikethrough() +
                        Text(" FREE One-Hour Delivery")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            HStack(alignment: .top){
                Circle()
                    .frame(width: circleSize, height: circleSize)
                    .foregroundColor(Color(.systemGray4))
                    .overlay(Circle()
                                .strokeBorder()
                                .foregroundColor(.secondary))
                VStack(alignment: .leading, spacing: spacing){
                    Text("Tomorrow")
                        .foregroundColor(.darkGreen)
                    Text(" FREE Same-Day Delivery")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            HStack(alignment: .top){
                Circle()
                    .frame(width: circleSize, height: circleSize)
                    .foregroundColor(Color(.systemGray4))
                    .overlay(Circle()
                                .strokeBorder()
                                .foregroundColor(.secondary))
                
                VStack(alignment: .leading, spacing: spacing){
                    Text("5-7 buissiness days")
                        .foregroundColor(.darkGreen)
                    Text(" FREE One-Hour Delivery")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
}

struct DeliveryOptions_Previews: PreviewProvider {
    static var previews: some View {
        DeliveryOptions()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
