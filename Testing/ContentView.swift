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
    @State var color = UIColor.black
    @State var clear = false
    var body : some View{
        Image("motorcycle")
            .resizable()
            .scaledToFit()
            .overlay(
                PKCanvas(color: $color, clear: $clear)
        )
            .edgesIgnoringSafeArea(.all)
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
    
    @Binding var color:UIColor
    @Binding var clear:Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.tool = PKInkingTool(.pen, color: color, width: 10)
        canvasView.isRulerActive = true
        canvasView.delegate = context.coordinator
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        canvasView.overrideUserInterfaceStyle = .light
        
        if let window = UIApplication.shared.windows.last, let toolPicker = PKToolPicker.shared(for: window) {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
        
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        if clear != context.coordinator.pkCanvas.clear{
            canvasView.drawing = PKDrawing()
        }
        canvasView.tool = PKInkingTool(.pen, color: color, width: 10)
    }
}
