//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    let offers: [String]
    
    var moreCount: Int {
        offers.count - 2
    }
    
    var body: some View {
        GeometryReader{ geo in
            HStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    Image("DORITOS")
                        .resizable()
                        .frame(width: 104, height: 104)
                        .clipShape(Circle())
                    
                    Chip(text: "🪙 10 per $1")
                        .alignmentGuide(HorizontalAlignment.center, computeValue: { _ in 10 } )
                        .alignmentGuide(.bottom) { d in d[.bottom] / 2 }
                    
                }
                .border(Color.orange)
                //
                //                if geo.size.width < 375 {
                //                    smallContainer
                //                } else {
                //                    largeContainer
                //                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
            .padding(.trailing, geo.size.width < 375 ? 8 : 4)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray, lineWidth: 1)
            )
            //            .padding()
            
            Text(geo.size.width.formatted())
        }
    }
    
    private var smallContainer: some View {
        HStack(spacing: 4) {
            if let offer = offers.first {
                OfferPreview(offer: offer)
            }
            
            if moreCount > 0 {
                Box(value: moreCount)
            }
        }
        .frame(width: 110, alignment: .leading)
        .border(Color.blue)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.leading, 12)
    }
    
    private var largeContainer: some View {
        HStack(spacing: 4) {
            ForEach(offers.prefix(2), id: \.self) { offer in
                OfferPreview(offer: offer)
            }
            
            if moreCount > 0 {
                Box(value: moreCount)
            }
        }
        .frame(width: 192, alignment: .leading)
        .border(Color.blue)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.leading, 12)
    }
}

struct OfferPreview: View {
    let offer: String
    
    var body: some View {
        ZStack(alignment: .centerLastTextBaseline) {
            Image(offer)
                .resizable()
                .frame(width: 78, height: 78)
                .cornerRadius(6)
                .layoutPriority(2)
            
            Chip(text: "🪙 1,000 ")
                .lineLimit(1)
        }
        .border(Color.red)
    }
}

struct Box: View {
    let value: Int
    
    var body: some View {
        Text("+\(value)")
            .font(.footnote)
            .frame(width: 28, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
}

struct Chip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.headline)
            .padding(.vertical, 3)
            .padding(.leading, 6)
            .padding(.trailing, 8)
            .background(
                ZStack {
                    Capsule()
                        .foregroundColor(.white)
                    Capsule()
                        .strokeBorder(
                            Color(.gray),
                            lineWidth: 1
                        )
                }
            )
    }
}

struct ContentView_Previews: PreviewProvider {
    static let devices = [
        "iPhone 14",
        "iPhone SE (3rd generation)",
        "iPod touch (7th generation)",
        "iPad Air (5th generation)",
    ]
    
    static var previews: some View {
        ForEach(devices, id: \.self) { device in
            //            VStack {
            //                ContentView(offers: ["offer1", "offer2", "offer3"])
            //                ContentView(offers: ["offer1", "offer2"])
            ContentView(offers: ["offer1"])
            //            }
                .previewLayout(.sizeThatFits)
                .previewDevice(PreviewDevice(rawValue: device))
        }
    }
}
