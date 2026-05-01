//
//  UIImage+Extension.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

import UIKit
import AVFoundation

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func merge(
        with topImage: UIImage,
        offset: CGPoint,
        alpha: CGFloat = 1
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            
            draw(in: rect)
            
            topImage.draw(
                in: .init(origin: offset, size: topImage.size),
                blendMode: .normal,
                alpha: alpha)
        }
    }
    
    func clipEdgets(amount: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath()
            
            //Top Left
            path.move(to: CGPoint(x: rect.minX + amount, y: rect.minY))
            
            //Top Right
            path.addLine(to: CGPoint(x: rect.maxX - amount, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + amount))
            
            //Bottom Right
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - amount))
            path.addLine(to: CGPoint(x: rect.maxX - amount, y: rect.maxY))
            
            //Bottom Left
            path.addLine(to: CGPoint(x: rect.minX + amount, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - amount))
            
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + amount))
            path.close()
            
            path.addClip()
            draw(in: rect)
        }
    }
}



extension Array where Element: UIImage {
    func stitchImages(isVertical: Bool, spacing:CGFloat) -> UIImage {
        let maxWidth = self.compactMap { $0.size.width }.max()
        let maxHeight = self.compactMap { $0.size.height }.max()
        let maxSize = CGSize(width: maxWidth ?? 0, height: maxHeight ?? 0)
        let size: CGSize
        
        if isVertical {
            size = CGSize(width: maxSize.width, height: maxSize.height * CGFloat(count))
        } else {
            size = CGSize(width: maxSize.width * CGFloat(count) + spacing, height:  maxSize.height)
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { (context) in
            for (index, image) in self.enumerated() {
                let s = index == 0 ? 0 : spacing
                
                let rect = AVMakeRect(aspectRatio: image.size, insideRect: isVertical ?
                                      CGRect(
                                        x: 0,
                                        y: maxSize.height * CGFloat(index),
                                        width: maxSize.width,
                                        height: maxSize.height
                                      ) :
                                        CGRect(
                                            x: maxSize.width * CGFloat(index) + s,
                                            y: 0,
                                            width: maxSize.width,
                                            height: maxSize.height
                                        )
                )
                
                image.draw(in: rect)
            }
        }
    }
}
