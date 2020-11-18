//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View{
    @State private var image: UIImage?
    
    var  body: some View{
        NavigationView{
            VStack{
                if let image = image{
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .onTapGesture{
                            self.image = nil
                        }
                }
                PhotoGrid(selectedImage: $image)
                    .edgesIgnoringSafeArea(.all)
                    .navigationTitle("Photo Grid")
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
