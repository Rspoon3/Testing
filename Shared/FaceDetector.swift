//
//  FaceDetector.swift
//  Testing
//
//  Created by Ricky on 3/13/25.
//

import Foundation
import Vision
import UIKit

struct FaceDetector {
    func detectFaces(
        in image: UIImage,
        scale: CGFloat = 1.0
    ) -> (UIImage?, [CGRect]) {
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
            guard let results = request.results, !results.isEmpty else {
                print("No faces detected")
                return (image, [])
            }
            
            // Get face rectangles in UIKit coordinates
            let imageSize = image.size
            var faceRects: [CGRect] = []
            var scaledFaces: [VNFaceObservation] = []
            
            for face in results {
                // Get original normalized rect
                let normalizedRect = face.boundingBox
                
                // Calculate the center of the face
                let centerX = normalizedRect.midX
                let centerY = normalizedRect.midY
                
                // Calculate new width and height with scaling
                let newWidth = normalizedRect.width * scale
                let newHeight = normalizedRect.height * scale
                
                // Calculate new origin (keeping the center fixed)
                let newX = centerX - (newWidth / 2)
                let newY = centerY - (newHeight / 2)
                
                // Create scaled normalized rect (clamped to valid bounds 0-1)
                let scaledNormalizedRect = CGRect(
                    x: max(0, min(1 - newWidth, newX)),
                    y: max(0, min(1 - newHeight, newY)),
                    width: min(1, newWidth),
                    height: min(1, newHeight)
                )
                
                // Create a mock VNFaceObservation with scaled boundingBox for drawing
                let scaledFace = VNFaceObservation(
                    boundingBox: scaledNormalizedRect
                )
                scaledFaces.append(scaledFace)
                
                // Convert to image coordinates
                let faceRect = VNImageRectForNormalizedRect(
                    scaledNormalizedRect,
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
            let processedImage = drawBoundingBoxes(on: image, faces: scaledFaces)
            return (processedImage, faceRects)
        } catch {
            print("Failed to perform face detection: \(error)")
            return (nil, [])
        }
    }
    
    private func drawBoundingBoxes(
        on image: UIImage,
        faces: [VNFaceObservation]
    ) -> UIImage? {
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
