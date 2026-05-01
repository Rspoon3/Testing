//
//  Shimmer.swift
//
//  Created by Vikram Kriplaney on 23.03.21.
//  Added by Patrick Stephen on 6/26/22.
//
//  [https://github.com/markiv/SwiftUI-Shimmer]
//  [https://stackoverflow.com/questions/77295575/swift-ui-shimmer-modifier-no-longer-works-on-ios-17]

import SwiftUI

/// A view modifier that adds an animated shimmering effect on a view.
///
/// To add this modifier to your view, call `.shimmering()` (or `.shining()`)
/// on your view.
public struct Shimmer: ViewModifier {
    private let min, max: CGFloat
    private let centerColor, edgeColor: Color
    private let animation: Animation
    @State private var isInitialState = true
    @Environment(\.layoutDirection) private var layoutDirection
    
    /// Initializes his modifier with a custom animation,
    /// - Parameters:
    ///   - duration: The duration of a shimmer cycle in seconds. Default: `1.5`.
    ///   - delay: The delay for the animation to begin. Default: `2`.
    ///   - bounce: Whether to bounce (reverse) the animation back and forth. Defaults to `false`.
    ///   - centerColor: The center color used for the gradient mask.
    ///   - edgeColor: The edge color used for the gradient mask.
    ///   - bandSize: The size of the animated mask's "band". Defaults to 0.3 unit points, which corresponds to
    /// 30% of the extent of the gradient.
    public init(
        duration: Double,
        delay: Double = 2.0,
        bounce: Bool,
        centerColor: Color = .black,
        edgeColor: Color = .black.opacity(0.3),
        bandSize: CGFloat = 0.3
    ) {
        self.centerColor = centerColor
        self.edgeColor = edgeColor
        self.animation = Animation.linear(duration: duration).delay(delay).repeatForever(autoreverses: bounce)
        
        // Calculate unit point dimensions beyond the gradient's edges by the band size
        self.min = 0 - bandSize
        self.max = 1 + bandSize
    }
    
    /*
     Calculating the gradient's animated start and end unit points:
     min,min
     \
     ┌───────┐         ┌───────┐
     │0,0    │ Animate │       │  "forward" gradient
     LTR │       │ ───────►│    1,1│  / // /
     └───────┘         └───────┘
     \
     max,max
     max,min
     /
     ┌───────┐         ┌───────┐
     │    1,0│ Animate │       │  "backward" gradient
     RTL │       │ ───────►│0,1    │  \ \\ \
     └───────┘         └───────┘
     /
     min,max
     */
    
//    /// The start unit point of our gradient, adjusting for layout direction.
//    var startPoint: UnitPoint {
//        if layoutDirection == .rightToLeft {
//            return isInitialState ? UnitPoint(x: max, y: min) : UnitPoint(x: 0, y: 1)
//        } else {
//            return isInitialState ? UnitPoint(x: min, y: min) : UnitPoint(x: 1, y: 1)
//        }
//    }
//    
//    /// The end unit point of our gradient, adjusting for layout direction.
//    var endPoint: UnitPoint {
//        if layoutDirection == .rightToLeft {
//            return isInitialState ? UnitPoint(x: 1, y: 0) : UnitPoint(x: min, y: max)
//        } else {
//            return isInitialState ? UnitPoint(x: 0, y: 0) : UnitPoint(x: max, y: max)
//        }
//    }
    
    /// The start unit point of our gradient, adjusting for layout direction.
    var startPoint: UnitPoint {
        return isInitialState ? UnitPoint(x: min, y: max) : UnitPoint(x: 1, y: 0)
    }
    
    /// The end unit point of our gradient, adjusting for layout direction.
    var endPoint: UnitPoint {
        return isInitialState ? UnitPoint(x: 0, y: 1) : UnitPoint(x: max, y: min)
    }
    
    public func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    colors: [edgeColor, centerColor, edgeColor],
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
            .onAppear {
                withAnimation(animation) {
                    isInitialState = false
                }
            }
    }
}

// MARK: - View Extensions

public extension View {
    /// Adds an animated shimmering effect to any view, typically to show that
    /// an operation is in progress.
    ///
    /// - Parameters:
    ///   - active: Convenience parameter to conditionally enable the effect. Defaults to `true`.
    ///   - duration: The duration of a shimmer cycle in seconds. Default: `1.5`.
    ///   - delay: The delay for the animation to begin. Default: `2`.
    ///   - bounce: Whether to bounce (reverse) the animation back and forth. Defaults to `false`.
    ///   - bandSize: The size of the animated mask's "band". Defaults to 0.3 unit points, which corresponds to
    /// 20% of the extent of the gradient.
    @ViewBuilder func shimmering(
        active: Bool = true,
        duration: Double = 1.5,
        delay: Double = 2.0,
        bounce: Bool = false,
        bandSize: CGFloat = 0.3
    ) -> some View {
        if active {
            modifier(
                Shimmer(
                    duration: duration,
                    delay: delay,
                    bounce: bounce,
                    bandSize: bandSize
                )
            )
        } else {
            self
        }
    }
    
    /// Adds an animated shining effect to any view.
    ///
    /// Shining just so happens to just be an inverted shimmer, so this effect
    /// is implemented as so.
    ///
    /// - Parameters:
    ///   - active: Convenience parameter to conditionally enable the effect. Defaults to `true`.
    ///   - duration: The duration of a shimmer cycle in seconds. Default: `1.5`.
    ///   - delay: The delay for the animation to begin. Default: `5`.
    ///   - bounce: Whether to bounce (reverse) the animation back and forth. Defaults to `false`.
    ///   - bandSize: The size of the animated mask's "band". Defaults to 0.3 unit points, which corresponds to
    /// 30% of the extent of the gradient.
    @ViewBuilder func shining(
        active: Bool = true,
        duration: Double = 1.5,
        delay: Double = 5,
        bounce: Bool = false,
        bandSize: CGFloat = 0.3
    ) -> some View {
        if active {
            modifier(
                Shimmer(
                    duration: duration,
                    delay: delay,
                    bounce: bounce,
                    centerColor: .black.opacity(0),
                    edgeColor: .black,
                    bandSize: bandSize
                )
            )
        } else {
            self
        }
    }
}

#if DEVELOPMENT

// MARK: - Previews

/// Previews for the shimmering (and shining) view modifiers.
struct ShimmerPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            Color.gray.frame(width: 200, height: 200)
                .shimmering()
                .previewDisplayName("Shimmering")
            Color.gray.frame(width: 200, height: 200)
                .shining()
                .previewDisplayName("Shining")
        }
    }
}

// MARK: - Library Content

/// A provider of content for the shimmering (and shining) view modifiers to
/// the Xcode Library.
struct ShimmerContentProvider: LibraryContentProvider {
    func modifiers(base: AnyView) -> [LibraryItem] {
        LibraryItem(base.shimmering())
        LibraryItem(base.shining())
    }
}

#endif
