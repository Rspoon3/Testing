//
//  PKCanvas.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 5/27/23.
//

import SwiftUI
import PencilKit

class MyPKCanvasView: PKCanvasView {
    var didUpdate: (() -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        didUpdate?()
    }
}

final class PKCanvasViewModel: NSObject, PKCanvasViewDelegate, ObservableObject {
    let canvasView = MyPKCanvasView()
    private let canvasWidth: CGFloat = 768
    private let canvasOverscrollHeight: CGFloat = 500
    @Published var zoomScale: CGFloat = 30
    
    override init() {
        super.init()
        canvasView.delegate = self
    }
    
    // MARK: - Private Helpers
    
    /// Helper method to set a suitable content size for the canvas view.
    func updateContentSizeForDrawing() {
        // Update the content size to match the drawing.
        let drawing = canvasView.drawing
        let contentHeight: CGFloat
        
        // Adjust the content size to always be bigger than the drawing height.
        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY + canvasOverscrollHeight) * canvasView.zoomScale)
            print("canvasView.contentSize 1")
        } else {
            contentHeight = canvasView.bounds.height
            print("canvasView.contentSize 2")
        }
        
        canvasView.contentSize = CGSize(width: canvasWidth * canvasView.zoomScale, height: contentHeight)
        
        print("canvasView.contentSize = ", canvasView.contentSize)
        print("canvasView.bounds.size = ", canvasView.bounds.size)
        print("DataModel.canvasWidth = ", canvasWidth)
        print("canvasView.zoomScale = ", canvasView.zoomScale)
        
        //canvasView.contentSize =  (768.0, 1180.0)
        //canvasView.bounds.size =  (820.0, 1180.0)
        //DataModel.canvasWidth =  768.0
        //canvasView.zoomScale =  1.0
    }
    
    func viewDidLayoutSubviews() {
        let canvasScale = canvasView.bounds.width / canvasWidth
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale
        
        print("Scale ", canvasScale, canvasView.bounds.width)

        // Scroll to the top.
        updateContentSizeForDrawing()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        let canvasScale = canvasView.bounds.width / canvasWidth
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale
        zoomScale = canvasScale
        
        print("Scale2 ", canvasScale, canvasView.bounds.width)
        
        updateContentSizeForDrawing()
        
//        print("canvasViewDrawingDidChange ", canvasView.contentSize, canvasView.bounds.size)
    }
}

struct PKCanvas: UIViewRepresentable {
    @Observable var viewModel: PKCanvasViewModel
    private let toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = viewModel.canvasView
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 15)
        canvasView.becomeFirstResponder()
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.alwaysBounceVertical = true
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
//        toolPicker.addObserver(self)
//        updateLayout(for: toolPicker)
        viewModel.canvasView.becomeFirstResponder()
        
        canvasView.didUpdate = {
            viewModel.viewDidLayoutSubviews()
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
//        DispatchQueue.main.async {
//            viewModel.viewDidLayoutSubviews()
//            print("updateUIView ", uiView.zoomScale, uiView.bounds.size, viewModel.canvasView.contentSize)
//            print(viewModel.canvasView.bounds.size, viewModel.canvasView.contentSize)
//        }
    }
}

struct PKCanvas_Previews: PreviewProvider {
    static var previews: some View {
        PKCanvas(viewModel: PKCanvasViewModel())
    }
}
