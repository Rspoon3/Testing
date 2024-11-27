import SwiftUI

struct Item {
    let number = Int.random(in: 1...99)
    let color = Color(.random())
    let startLocation = CGPoint(
        x: CGFloat.random(in: -300...300),
        y: CGFloat.random(in: -300...300)
    )
}

struct MovingNumbers: View {
    private let items = (0..<15).map { _ in Item() }
    private let animationDuration: Double = 10.0 // Duration for one full motion
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let screenWidth = size.width
                let screenHeight = size.height
                let center = CGPoint(x: screenWidth / 2, y: screenHeight / 2)
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for item in items {
                    // Calculate progress for back-and-forth motion
                    let progress = (time / animationDuration).truncatingRemainder(dividingBy: 1)
                    let backAndForthProgress = progress < 0.5
                        ? progress * 2 // 0 to 1 for the first half
                        : (1 - progress) * 2 // 1 to 0 for the second half
                    
                    // Interpolate position from center to random destination
                    let currentPosition = CGPoint(
                        x: center.x + backAndForthProgress * item.startLocation.x,
                        y: center.y + backAndForthProgress * item.startLocation.y
                    )
                    
                    // Calculate blur amount based on progress
                    let blurAmount = backAndForthProgress * 4
                    
                    // Calculate scale factor
                    let scaleFactor = 1 + backAndForthProgress * 0.5
                    
                    // Render the number text
                    let attributedString = AttributedString("\(item.number)")
                    
                    let resolvedText = context.resolve(Text(attributedString)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(item.color))
                    
                    // Apply scaling and blur
                    context.drawLayer { layerContext in
                        // Apply blur
                        layerContext.addFilter(.blur(radius: blurAmount))
                        
                        // Apply scaling by transforming the context
                        layerContext.translateBy(x: currentPosition.x, y: currentPosition.y)
                        layerContext.scaleBy(x: scaleFactor, y: scaleFactor)
                        layerContext.translateBy(x: -currentPosition.x, y: -currentPosition.y)
                        
                        // Draw the text
                        layerContext.draw(resolvedText, at: currentPosition)
                    }
                }
            }
        }
    }
}
