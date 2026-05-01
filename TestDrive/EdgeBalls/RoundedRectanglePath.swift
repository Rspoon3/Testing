import SwiftUI

struct RoundedRectanglePath {
    let rect: CGRect
    let cornerRadius: CGFloat
    let effectiveRadius: CGFloat
    let perimeter: CGFloat
    let topCenterOffset: CGFloat
    
    init(rect: CGRect, cornerRadius: CGFloat) {
        self.rect = rect
        self.cornerRadius = cornerRadius
        
        // Pre-compute values
        self.effectiveRadius = min(cornerRadius, min(rect.width/2, rect.height/2))
        
        let straightHorizontal = rect.width - 2 * effectiveRadius
        let straightVertical = rect.height - 2 * effectiveRadius
        let cornerPerimeter = 2 * .pi * effectiveRadius
        self.perimeter = 2 * straightHorizontal + 2 * straightVertical + cornerPerimeter
        
        let straightTop = rect.width - 2 * effectiveRadius
        self.topCenterOffset = straightTop / 2
    }
    
    func point(at distance: CGFloat) -> CGPoint {
        let width = rect.width
        let height = rect.height
        let radius = effectiveRadius
        
        let straightTop = width - 2 * radius
        let straightRight = height - 2 * radius
        let straightBottom = width - 2 * radius
        let straightLeft = height - 2 * radius
        let cornerLength = radius * .pi / 2
        
        var adjustedDistance = distance.truncatingRemainder(dividingBy: perimeter)
        if adjustedDistance < 0 {
            adjustedDistance += perimeter
        }
        
        var currentDistance: CGFloat = 0
        
        // Top straight
        if adjustedDistance <= straightTop {
            return CGPoint(x: rect.minX + radius + adjustedDistance, y: rect.minY)
        }
        currentDistance += straightTop
        
        // Top-right corner
        if adjustedDistance <= currentDistance + cornerLength {
            let angle = (adjustedDistance - currentDistance) / cornerLength * .pi / 2
            return CGPoint(
                x: rect.maxX - radius + radius * sin(angle),
                y: rect.minY + radius - radius * cos(angle)
            )
        }
        currentDistance += cornerLength
        
        // Right straight
        if adjustedDistance <= currentDistance + straightRight {
            return CGPoint(x: rect.maxX, y: rect.minY + radius + (adjustedDistance - currentDistance))
        }
        currentDistance += straightRight
        
        // Bottom-right corner
        if adjustedDistance <= currentDistance + cornerLength {
            let angle = (adjustedDistance - currentDistance) / cornerLength * .pi / 2
            return CGPoint(
                x: rect.maxX - radius + radius * cos(angle),
                y: rect.maxY - radius + radius * sin(angle)
            )
        }
        currentDistance += cornerLength
        
        // Bottom straight
        if adjustedDistance <= currentDistance + straightBottom {
            return CGPoint(x: rect.maxX - radius - (adjustedDistance - currentDistance), y: rect.maxY)
        }
        currentDistance += straightBottom
        
        // Bottom-left corner
        if adjustedDistance <= currentDistance + cornerLength {
            let angle = (adjustedDistance - currentDistance) / cornerLength * .pi / 2
            return CGPoint(
                x: rect.minX + radius - radius * sin(angle),
                y: rect.maxY - radius + radius * cos(angle)
            )
        }
        currentDistance += cornerLength
        
        // Left straight
        if adjustedDistance <= currentDistance + straightLeft {
            return CGPoint(x: rect.minX, y: rect.maxY - radius - (adjustedDistance - currentDistance))
        }
        currentDistance += straightLeft
        
        // Top-left corner
        let angle = (adjustedDistance - currentDistance) / cornerLength * .pi / 2
        return CGPoint(
            x: rect.minX + radius - radius * cos(angle),
            y: rect.minY + radius - radius * sin(angle)
        )
    }
    
    func hourPosition(for hour: Int) -> CGPoint {
        // Calculate position with 12 at top center
        let hourOffset = hour == 12 ? 0 : hour
        let hourFraction = CGFloat(hourOffset) / 12.0
        let distance = topCenterOffset + hourFraction * perimeter
        
        return point(at: distance)
    }
    
    func timePosition(for fraction: Double) -> CGPoint {
        let distance = topCenterOffset + CGFloat(fraction) * perimeter
        return point(at: distance)
    }
}