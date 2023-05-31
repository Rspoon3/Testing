//
//  PKCanvas.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 5/27/23.
//

import SwiftUI
import PencilKit

struct PKCanvas: UIViewRepresentable {
    private let picker = PKToolPicker()
    private let canvasView = PKCanvasView()
    
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
    
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var pkCanvas: PKCanvas
        
        init(_ pkCanvas: PKCanvas) {
            self.pkCanvas = pkCanvas
        }
    }
}

struct PKCanvas_Previews: PreviewProvider {
    static var previews: some View {
        PKCanvas()
    }
}
