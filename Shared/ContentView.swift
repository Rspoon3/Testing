//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import FLAnimatedImage

struct ContentView: View {
    let localImage = FLAnimatedImage(gifData: gifData)!
    @State private var image: FLAnimatedImage?
    
    var body: some View {
        VStack {
            GIFView(image: localImage)
                .frame(width: 200, height: 100)
            
            if let image {
                GIFView(image: image)
                    .frame(width: 200, height: 100)
            }
        }
        .task {
            Task(priority: .userInitiated) {
                let url = URL(string: "https://cdn.staging-images.fetchrewards.com/carousels/38376a7ce028e5ba94fb51c85ced5e8f13c47399.gif")!
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    image = .init(gifData: data)
                } catch {}
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
