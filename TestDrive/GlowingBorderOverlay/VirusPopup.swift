//
//  VirusPopup.swift
//  TestDrive
//

import SwiftUI

/// A single 90s-style popup window rendered inside the overlay canvas.
/// Picks up its title/body/button/colors from the supplied ``PopupSpec`` and
/// applies the `spec.animation` animation continuously while it's on screen.
///
/// The popup is purely cosmetic — our overlay window is click-through, so the
/// "✕" close button and the action button can't actually be clicked. That's
/// fine; the effect is meant to evoke an avalanche of dialogs, not let the
/// user dismiss them.
struct VirusPopup: View {
    let spec: PopupSpec
    let width: CGFloat
    let scale: CGFloat

    @State private var animating = false

    // MARK: - Initializer

    init(spec: PopupSpec, width: CGFloat = 290, scale: CGFloat = 1.0) {
        self.spec = spec
        self.width = width
        self.scale = scale
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            body_
        }
        .frame(width: width)
        .overlay(Rectangle().stroke(.black, lineWidth: 2))
        .modifier(VirusAnimationModifier(animation: spec.animation, isOn: animating))
        .scaleEffect(scale)
        .onAppear {
            withAnimation(animationCurve(for: spec.animation)) {
                animating = true
            }
        }
    }

    // MARK: - Private Views

    private var titleBar: some View {
        HStack(spacing: 6) {
            Text(spec.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(spec.titleTextColor)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text("✕")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Color.red)
                .overlay(Rectangle().stroke(.white, lineWidth: 1))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(spec.titleBarColor)
    }

    private var body_: some View {
        VStack(spacing: 14) {
            Text(spec.body)
                .font(spec.bodyFont)
                .foregroundStyle(spec.bodyText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(spec.buttonLabel)
                .font(.system(.body).weight(.bold))
                .foregroundStyle(spec.buttonText)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(spec.buttonBackground)
                .overlay(Rectangle().stroke(.black, lineWidth: 1))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(spec.bodyBackground)
    }

    // MARK: - Private Helpers

    private func animationCurve(for animation: PopupAnimation) -> Animation {
        switch animation {
        case .flash: .easeInOut(duration: 0.35).repeatForever(autoreverses: true)
        case .pulse: .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
        case .shake: .easeInOut(duration: 0.18).repeatForever(autoreverses: true)
        case .rainbow: .linear(duration: 3.0).repeatForever(autoreverses: false)
        case .marquee: .easeInOut(duration: 0.4).repeatForever(autoreverses: true)
        }
    }
}

/// Per-animation visual modifier. Reads from the boolean `isOn` state on the
/// popup so SwiftUI animates the transition between the two endpoints.
private struct VirusAnimationModifier: ViewModifier {
    let animation: PopupAnimation
    let isOn: Bool

    func body(content: Content) -> some View {
        switch animation {
        case .flash:
            content.opacity(isOn ? 1.0 : 0.45)
        case .pulse:
            content.scaleEffect(isOn ? 1.07 : 0.93)
        case .shake:
            content.rotationEffect(.degrees(isOn ? 2.5 : -2.5))
        case .rainbow:
            content.hueRotation(.degrees(isOn ? 360 : 0))
        case .marquee:
            content.brightness(isOn ? 0.18 : -0.06)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        VirusPopup(spec: PopupSpec.catalog[0])
        VirusPopup(spec: PopupSpec.catalog[1])
        VirusPopup(spec: PopupSpec.catalog[5])
    }
    .padding(40)
    .background(Color.black)
}
