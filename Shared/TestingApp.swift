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

// Face tracking model to maintain state of each face
struct FaceCircle: Identifiable {
    let id = UUID()
    var rect: CGRect
    var isVisible: Bool = false
}

struct FaceDetectionView: View {
    @State private var selectedImage: UIImage? = UIImage(named: "ricky") // Replace with actual image
    @State private var faceImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var faceCircles: [FaceCircle] = []
    @State private var circleAnimating = false
    @AppStorage("scale") var scale: Double = 1

    private let faceDetector = FaceDetector()
    
    var body: some View {
        VStack {
            Stepper("scale \(scale.formatted())", value: $scale, step: 0.1)
            
            if let faceImage {
                Image(uiImage: faceImage)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        GeometryReader { proxy in
                            ForEach(faceCircles) { faceCircle in
                                let rect = calculateScaledRect(originalRect: faceCircle.rect, in: proxy)
                                
                                Circle()
                                    .stroke(Color.blue, lineWidth: 4)
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                                    .opacity(faceCircle.isVisible ? 1 : 0)
                            }
                        }
                    )
            } else if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        GeometryReader { proxy in
                            ForEach(faceCircles) { faceCircle in
                                let rect = calculateScaledRect(originalRect: faceCircle.rect, in: proxy)
                                
                                Circle()
                                    .stroke(Color.blue, lineWidth: 4)
                                    .frame(width: rect.width, height: rect.height)
                                    .position(x: rect.midX, y: rect.midY)
                                    .opacity(faceCircle.isVisible ? 1 : 0)
                            }
                        }
                    )
            }
            
            Button("Detect Faces") {
                detectFaces()
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
            try? await Task.sleep(for: .seconds(0.5))
            detectFaces()
        }
    }
    
    private func detectFaces() {
        guard let selectedImage else { return }
        let (image, rect) = faceDetector.detectFaces(
            in: selectedImage,
            scale: scale
        )
        faceImage = image
        
        updateFaceCircles(with: rect)
        
        if let faceImage, let first = rect.first {
            self.faceImage = cropImageToFirstFace(image: faceImage, faceRect: first)
        }
    }
    
    func cropImageToFirstFace(image: UIImage, faceRect: CGRect) -> UIImage? {
        // Convert CGRect to pixel-based coordinates
        let scale = image.scale
        let cropRect = CGRect(
            x: faceRect.origin.x * scale,
            y: faceRect.origin.y * scale,
            width: faceRect.width * scale,
            height: faceRect.height * scale
        )
        
        // Perform cropping
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
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
        }
    }
    
    // Update face circles with smooth transition
    private func updateFaceCircles(with newRects: [CGRect]) {
        // If this is the first detection or we have no circles, create new ones
        if faceCircles.isEmpty {
            faceCircles = newRects.map { FaceCircle(rect: $0, isVisible: false) }
            
            // Delay to let the UI update first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.5)) {
                    // Make all circles visible
                    for index in faceCircles.indices {
                        faceCircles[index].isVisible = true
                    }
                }
            }
            return
        }
        
        // If we already have face circles, animate them to their new positions
        
        // Create temporary copy of current circles
        let oldCircles = faceCircles
        
        // First, handle case where we have more new faces than existing circles
        if newRects.count > oldCircles.count {
            // Add new circles for the additional faces (initially invisible)
            let additionalCircles = (oldCircles.count..<newRects.count).map {
                FaceCircle(rect: newRects[$0], isVisible: false)
            }
            faceCircles.append(contentsOf: additionalCircles)
        }
        
        // If we have fewer new faces, keep the existing circles but prepare to hide extras
        if newRects.count < oldCircles.count {
            // We'll update the visibility later
        }
        
        // Delay to let the UI update first if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.5)) {
                // Update positions for existing circles and make visible
                for index in 0..<min(faceCircles.count, newRects.count) {
                    faceCircles[index].rect = newRects[index]
                    faceCircles[index].isVisible = true
                }
                
                // Hide any extra circles if we have fewer faces now
                if newRects.count < faceCircles.count {
                    for index in newRects.count..<faceCircles.count {
                        faceCircles[index].isVisible = false
                    }
                }
                
                // Make any new circles visible
                if newRects.count > oldCircles.count {
                    for index in oldCircles.count..<faceCircles.count {
                        faceCircles[index].isVisible = true
                    }
                }
            }
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
