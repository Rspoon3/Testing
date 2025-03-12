//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Vision
import PhotosUI

@main
struct TestingApp: App {
    var body: some Scene {
        WindowGroup {
            FaceDetectionView()
        }
    }
}

struct FaceDetectionView: View {
    @State private var selectedImage: UIImage? = UIImage(named: "ricky") // Replace with actual image
    @State private var faceImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var faceRects: [CGRect] = []
    @State private var circleAnimating = false

    private let faceDetector = FaceDetector()
    
    var body: some View {
        VStack {
            if let faceImage {
                Image(uiImage: faceImage)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        GeometryReader { proxy in
                            ForEach(faceRects.indices, id: \.self) { index in
                                let rect = calculateScaledRect(originalRect: faceRects[index], in: proxy)
                                
                                Circle()
                                    .stroke(Color.blue, lineWidth: 4)
                                    .frame(width: circleAnimating ? rect.width : 0,
                                           height: circleAnimating ? rect.height : 0)
                                    .position(x: rect.midX, y: rect.midY)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.5), value: circleAnimating)
                            }
                        }
                    )
            } else if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
            }
            
            Button("Detect Faces") {
                guard let selectedImage else { return }
                let (image, rect) = faceDetector.detectFaces(in: selectedImage)
                faceImage = image
                faceRects = rect
                
                circleAnimating = false
                // Trigger animation after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        circleAnimating = true
                    }
                }
            }
            .padding()
            
            Button("Pick Photo") {
                showPhotoPicker = true
            }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $photosPickerItem,
            matching: .images
        )
        .task(id: photosPickerItem) {
            await handlePhotoSelection()
        }
    }
    
    @MainActor
    func handlePhotoSelection() async {
        guard
            let imageData = try? await photosPickerItem?.loadTransferable(type: Data.self),
            let loadedImage = UIImage(data: imageData)
        else {
            selectedImage = nil
            faceImage = nil
            return
        }
        
        withAnimation(.spring()) {
            faceImage = nil
            selectedImage = loadedImage
            faceRects = []
            circleAnimating = false
        }
    }
    
    // Calculate scaled rect position based on the container size
       private func calculateScaledRect(originalRect: CGRect, in proxy: GeometryProxy) -> CGRect {
           guard let selectedImage = selectedImage else { return .zero }
           
           let imageSize = selectedImage.size
           let containerSize = proxy.size
           
           // Calculate scaling factor
           let widthRatio = containerSize.width / imageSize.width
           let heightRatio = containerSize.height / imageSize.height
           let scale = min(widthRatio, heightRatio)
           
           // Calculate scaled dimensions
           let scaledWidth = originalRect.width * scale
           let scaledHeight = originalRect.height * scale
           
           // Calculate position in container
           // Account for letterboxing (if any)
           let imageWidth = imageSize.width * scale
           let imageHeight = imageSize.height * scale
           let xOffset = (containerSize.width - imageWidth) / 2
           let yOffset = (containerSize.height - imageHeight) / 2
           
           let x = originalRect.origin.x * scale + xOffset
           let y = originalRect.origin.y * scale + yOffset
           
           return CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
       }
}

#Preview {
    FaceDetectionView()
}

import UIKit
import Vision

struct FaceDetector {
    func detectFaces(in image: UIImage) -> (UIImage?, [CGRect]) {
        // Convert UIImage to CIImage
        guard let ciImage = CIImage(image: image) else {
            print("Failed to create CIImage from UIImage")
            return (nil, [])
        }
        
        // Create a face detection request
        let request = VNDetectFaceRectanglesRequest()
        
        // Create a request handler with the image's orientation
        let imageOrientation = CGImagePropertyOrientation(image.imageOrientation)
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: imageOrientation)
        
        // Perform the face detection request
        do {
            try requestHandler.perform([request])
            
            // Check if faces were detected
            guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                print("No faces detected")
                return (image, [])
            }
            
            // Get face rectangles in UIKit coordinates
            let imageSize = image.size
            var faceRects: [CGRect] = []
            
            for face in results {
                let faceRect = VNImageRectForNormalizedRect(
                    face.boundingBox,
                    Int(imageSize.width),
                    Int(imageSize.height)
                )
                
                // Convert from Vision coordinates (origin at bottom-left) to UIKit coordinates (origin at top-left)
                let convertedRect = CGRect(
                    x: faceRect.origin.x,
                    y: imageSize.height - faceRect.origin.y - faceRect.height,
                    width: faceRect.width,
                    height: faceRect.height
                )
                
                faceRects.append(convertedRect)
            }
            
            // Draw bounding boxes around the detected faces
            let processedImage = drawBoundingBoxes(on: image, faces: results)
            return (processedImage, faceRects)
        } catch {
            print("Failed to perform face detection: \(error)")
            return (nil, [])
        }
    }
    
    private func drawBoundingBoxes(on image: UIImage, faces: [VNFaceObservation]) -> UIImage? {
        // Create a graphics context with the same size as the image
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        
        // Draw the original image
        image.draw(at: CGPoint.zero)
        
        // Get the current graphics context
        guard let context = UIGraphicsGetCurrentContext() else {
            print("Failed to create graphics context")
            UIGraphicsEndImageContext()
            return nil
        }
        
        // Set up the appearance of the bounding box
        context.setStrokeColor(UIColor.random().cgColor)
        context.setLineWidth(5.0)
        
        // Get the image dimensions
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        
        // Vision uses a coordinate system with origin at bottom-left
        // UIKit uses a coordinate system with origin at top-left
        // We need to flip the y-coordinate
        context.translateBy(x: 0, y: imageHeight)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Draw a bounding box for each detected face
        for face in faces {
            // Convert normalized coordinates to image coordinates
            let faceRect = VNImageRectForNormalizedRect(
                face.boundingBox,
                Int(imageWidth),
                Int(imageHeight)
            )
            
            // Draw the bounding box
            context.stroke(faceRect)
        }
        
        // Get the image from the context
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the graphics context
        UIGraphicsEndImageContext()
        
        return resultImage
    }
}

// Extension to convert UIImage.Orientation to CGImagePropertyOrientation
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}


