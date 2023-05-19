//
//  UIImage+Extension.swift
//  Testing
//
//  Created by Richard Witherspoon on 5/19/23.
//

import UIKit
import AVFoundation

extension UIImage {
    func scaled(to percentage: Double) -> UIImage {
        let scaledSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        let availableRect = AVMakeRect(aspectRatio: size, insideRect: .init(origin: .zero, size: scaledSize))
        let targetSize = availableRect.size
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

extension Array where Element: UIImage {
    func stitchImages(isVertical: Bool, spacing: CGFloat) -> UIImage {
        let imagesWidth = map(\.size.width).reduce(0, +)
        
        let maxWidth = self.compactMap { $0.size.width }.max()
        let maxHeight = self.compactMap { $0.size.height }.max() ?? 0
        let maxSize = CGSize(width: maxWidth ?? 0, height: maxHeight)
        let size: CGSize
        
        if isVertical {
            size = CGSize(width: maxSize.width, height: maxSize.height * CGFloat(count))
        } else {
            let totalSpacing = spacing * CGFloat(count - 1)
            size = CGSize(width: imagesWidth + totalSpacing, height: maxSize.height)
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { (context) in
            var previousX: CGFloat = 0
            
            for (index, image) in self.enumerated() {
                let insideRect: CGRect
                
                if isVertical {
                    insideRect = CGRect(
                        x: 0,
                        y: maxSize.height * CGFloat(index),
                        width: maxSize.width,
                        height: maxSize.height
                    )
                } else {
                    let x: CGFloat
                    
                    if index == 0 {
                        x = 0
                    } else {
                        x = previousX + spacing
                    }
                    
                    insideRect = CGRect(
                        x: x,
                        y: 0,
                        width: image.size.width,
                        height: maxSize.height
                    )
                    
                    previousX = insideRect.maxX
                }
                
                let rect = AVMakeRect(
                    aspectRatio: image.size,
                    insideRect: insideRect
                )
                
                image.draw(in: rect)
            }
        }
    }
}
