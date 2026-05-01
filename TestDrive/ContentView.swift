//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import ImagePlayground

struct ContentView: View {
    @State private var showImagePlayground = false
    @State private var createdImageURL: URL?
    
    // Fallback value for supportsImagePlayground
       private var isImagePlaygroundSupported: Bool {
           if #available(iOS 18.1, *) {
               return ImagePlaygroundViewController.isAvailable
           } else {
               return false
           }
       }
    
    var body: some View {
        VStack {
            if let createdImageURL {
                AsyncImage(url: createdImageURL) { image in
                    image.resizable().aspectRatio(contentMode: .fit).frame(maxWidth: 300, maxHeight: 300)
                } placeholder: {
                    ProgressView()
                }
            }
            
            if isImagePlaygroundSupported {
                Button("Show Generation Sheet") {
                    showImagePlayground = true
                }
                .backDeployedImagePlaygroundSheet(isPresented: $showImagePlayground) { url in
                    createdImageURL = url
                }
               
            } else {
                Text("bad")
            }
        }
    }
}

extension View {
    @MainActor @preconcurrency
    func backDeployedImagePlaygroundSheet(
        isPresented: Binding<Bool>,
        sourceImage: Image? = nil,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        if #available(iOS 18.1, *) {
            return self.imagePlaygroundSheet(
                isPresented: isPresented,
                onCompletion: onCompletion,
                onCancellation: onCancellation
            )
        } else {
            return self
        }
    }
}

#Preview {
    ContentView()
}
