//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var image: UIImage?
    let images = [
        "screenshot1",
        "screenshot2",
        "screenshot3",
        "screenshot4",
        "screenshot5",
    ].compactMap{
        let image = UIImage(named: $0)
        return image?.scaled(to: 0.1)
    }
    
    let resized1 = UIImage(named: "screenshot1")!.scaled(to: 0.6)
    
    var body: some View {
        VStack {
            HStack {
                Image(uiImage: resized1)
                    .resizable()
                    .scaledToFit()
                
                Image("screenshot1")
                    .resizable()
                    .scaledToFit()
            }
            
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .onAppear {
                        print(images.map(\.size.width).reduce(0, +))
                        image = images.stitchImages(isVertical: false, spacing: 50)
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
