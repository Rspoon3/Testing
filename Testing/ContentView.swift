//
//  ContentView.swift
//  Testing
//
//  Created by Richard Witherspoon on 11/4/19.
//  Copyright © 2019 Richard Witherspoon. All rights reserved.
//

import SwiftUI
import PencilKit

struct ContentView : View {
    @State var title = "Title"
    @State var showLines = true
    
    var body : some View{
        NavigationView{
            VStack(alignment: .leading){
                VStack(alignment: .leading){
                    TextField("", text: $title)
                        .font(.largeTitle)
                    Text("July 17, 2020 at 2:40pm")
                }.padding()
                GeometryReader{ geo in
                    VStack(spacing: 34){
                        ForEach(0..<200){ _ in
                            Divider()
                        }
                    }.opacity(showLines ? 1 : 0)
                    PKCanvas()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lines"){
                        withAnimation(Animation.linear(duration: 0.15)){
                            showLines.toggle()
                        }
                    }
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct PKCanvas: UIViewRepresentable {
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var pkCanvas: PKCanvas
        
        init(_ pkCanvas: PKCanvas) {
            self.pkCanvas = pkCanvas
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    let picker = PKToolPicker()
    let canvasView = PKCanvasView()
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 15)
        canvasView.becomeFirstResponder()
        canvasView.delegate = context.coordinator
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        picker.addObserver(canvasView)
        picker.setVisible(true, forFirstResponder: canvasView)
        return canvasView
    }
    
      func updateUIView(_ uiView: PKCanvasView, context: Context) {
      }
}
