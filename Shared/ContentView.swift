//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Combine


class ContentViewModel: ObservableObject{
    @Published var image: UIImage?
}

struct ContentView: View{
    @StateObject var model = ContentViewModel()
    
    var  body: some View{
        VStack{
            if let image = model.image{
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .onTapGesture {
                        model.image = nil
                    }
            }
            PhotoGrid(selectedImage: $model.image)
                .edgesIgnoringSafeArea(.all)
                .navigationTitle("Photo Grid")
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
