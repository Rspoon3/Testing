//
//  MovingNumbersBackgroundUIViewRepresentable.swift
//  Testing
//
//  Created by Ricky on 11/27/24.
//

import SwiftUI

struct MovingNumbersBackgroundUIViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        MovingNumbersBackgroundUIView(frame: .zero)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
}

class MovingNumbersBackgroundUIView: UIView {
    private let numberCount = 20
    private var layout = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard layout, frame != .zero else { return }
        layout = false
        
        // Add moving glowing numbers
        for _ in 0..<numberCount {
            addGlowingNumber()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createPositionAnimation() -> CAAnimation {
        let animation = CABasicAnimation(keyPath: "position")
        
        // Randomize the movement within ±50 units of the starting position
        let startPoint = randomPosition()
        let randomXOffset = CGFloat.random(in: -50...50)
        let randomYOffset = CGFloat.random(in: -50...50)
        let targetPoint = CGPoint(
            x: startPoint.x + randomXOffset,
            y: startPoint.y + randomYOffset
        )
        
        // Set the animation's from and to values
        animation.fromValue = startPoint
        animation.toValue = targetPoint
        
        animation.duration = Double.random(in: 5...10)
        animation.autoreverses = true
        animation.isRemovedOnCompletion = false // Prevent removal on backgrounding
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        return animation
    }
    
    private func randomPosition() -> CGPoint {
        let screenWidth = bounds.width
        let screenHeight = bounds.height
        
        return CGPoint(
            x: CGFloat.random(in: 0...screenWidth),
            y: CGFloat.random(in: 0...screenHeight)
        )
    }
    
    private func addGlowingNumber() {
        // Create the text layer
        let textLayer = CATextLayer()
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.string = "\(Int.random(in: 1...99))"
        textLayer.font = UIFont.boldSystemFont(ofSize: 40)
        textLayer.fontSize = CGFloat.random(in: 12...25)
        textLayer.foregroundColor = UIColor.randomColor().withAlphaComponent(0.8).cgColor
        textLayer.alignmentMode = .center
        
        // Size the text layer to fit the text
        let fontSize = textLayer.fontSize
        let textSize = "\(textLayer.string!)".size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: fontSize)])
        textLayer.frame = CGRect(origin: .zero, size: textSize)

        // Render the text layer to an image with padding for the blur
        let padding: CGFloat = 20
        let textImage = renderLayerToImage(textLayer: textLayer, padding: padding)

        // Apply Gaussian blur using Core Image
        let blurredImage = applyBlurToImage(image: textImage, radius: CGFloat.random(in: 2...8))

        // Add the blurred image as a UIImageView
        let imageView = UIImageView(image: blurredImage)
        imageView.frame = CGRect(origin: .zero, size: blurredImage.size)
        imageView.center = randomPosition()

        addSubview(imageView)

        // Add position animation
        let animation = createPositionAnimation()
        imageView.layer.add(animation, forKey: "move")
    }

    private func renderLayerToImage(textLayer: CATextLayer, padding: CGFloat) -> UIImage {
        // Calculate the size of the image, including padding
        let imageSize = CGSize(
            width: textLayer.bounds.width + 2 * padding,
            height: textLayer.bounds.height + 2 * padding
        )

        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { context in
            // Offset the context to center the text layer within the padded image
            context.cgContext.translateBy(x: padding, y: padding)
            textLayer.render(in: context.cgContext)
        }
    }

    private func applyBlurToImage(image: UIImage, radius: CGFloat) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let ciImage = CIImage(cgImage: cgImage)
        let blurFilter = CIFilter(name: "CIGaussianBlur")

        blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(radius, forKey: kCIInputRadiusKey)

        let context = CIContext()

        guard
            let outputImage = blurFilter?.outputImage,
            let cgBlurredImage = context.createCGImage(outputImage, from: ciImage.extent)
        else {
            return image
        }

        return UIImage(cgImage: cgBlurredImage)
    }
}

extension UIColor {
    static func randomColor() -> UIColor {
        return UIColor(
            red: CGFloat.random(in: 0.3...1),
            green: CGFloat.random(in: 0.3...1),
            blue: CGFloat.random(in: 0.3...1),
            alpha: 1.0
        )
    }
}
