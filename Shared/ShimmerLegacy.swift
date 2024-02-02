//
//  ShimmerLegacy.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/1/24.
//

import SwiftUI

// MARK: - Shimmering

/// A view modifier that adds an animated shimmering effect on a view.
///
/// To add this modifier to your view, call `.shimmering()` (or `.shining()`)
/// on your view.
struct ShimmerLegacy: ViewModifier {

    // MARK: Properties

    @State private var phase: CGFloat = 0
    var duration = 1.5
    var delay = 2.0
    var bounce = false
    let centerColor: Color
    let edgeColor: Color

    // MARK: Initializers

    init(
        duration: Double,
        delay: Double = 2.0,
        bounce: Bool,
        centerColor: Color = .black,
        edgeColor: Color = .black.opacity(0.3)
    ) {
        self.duration = duration
        self.delay = delay
        self.bounce = bounce
        self.centerColor = centerColor
        self.edgeColor = edgeColor
    }

    // MARK: Body

    public func body(content: Content) -> some View {

        // This modifier causes major performance issues on Xcode 15, iOS 17.
        if #unavailable(iOS 17.0) {
            content
                .modifier(
                    AnimatedMask(phase: phase, centerColor: centerColor, edgeColor: edgeColor)
                        .animation(Animation.linear(duration: duration).delay(delay).repeatForever(autoreverses: bounce))
                )
                .onAppear { phase = 0.8 }
        } else {
            content
        }
    }

    // MARK: Helper Objects

    /// An animatable modifier to interpolate between `phase` values.
    struct AnimatedMask: AnimatableModifier {
        var phase: CGFloat = 0
        let centerColor: Color
        let edgeColor: Color

        var animatableData: CGFloat {
            get { phase }
            set { phase = newValue }
        }

        init(phase: CGFloat, centerColor: Color, edgeColor: Color = .black.opacity(0.3)) {
            self.phase = phase
            self.centerColor = centerColor
            self.edgeColor = edgeColor
        }

        func body(content: Content) -> some View {
            content
                .mask(mask(phase: phase).scaleEffect(3))
        }

        /// A slanted, animatable gradient between transparent and opaque to
        /// use as a mask.
        ///
        /// The `phase` parameter shifts the gradient, moving the opaque band.
        @ViewBuilder func mask(phase: Double) -> some View {
            LinearGradient(
                gradient: .init(stops: [
                        .init(color: edgeColor, location: phase),
                        .init(color: centerColor, location: phase + 0.1),
                        .init(color: edgeColor, location: phase + 0.2)
                    ]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
    ///   - bounce: Whether to bounce (reverse) the animation back and forth. Defaults to `false`.
    @ViewBuilder func shimmeringLegacy(
        active: Bool = true,
        duration: Double = 1.5,
        delay: Double = 2.0,
        bounce: Bool = false
    ) -> some View {
        if active {
            modifier(ShimmerLegacy(duration: duration, delay: delay, bounce: bounce))
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
    ///   - bounce: Whether to bounce (reverse) the animation back and forth. Defaults to `false`.
    @ViewBuilder func shiningLegacy(
        active: Bool = true,
        duration: Double = 1.5,
        delay: Double = 5,
        bounce: Bool = false
    ) -> some View {
        if active {
            modifier(
                ShimmerLegacy(
                    duration: duration,
                    delay: delay,
                    bounce: bounce,
                    centerColor: .black.opacity(0.3),
                    edgeColor: .black
                )
            )
        } else {
            self
        }
    }
}
