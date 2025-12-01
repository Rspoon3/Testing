//
//  MoonPhaseScrollDemoView.swift
//  TestDrive
//
//  Created by Claude Code
//

import SwiftUI

/// A demo view that showcases the circle-to-line moon phase animation with scroll tracking.
struct MoonPhaseScrollDemoView: View {
    @State private var scrollOffset: CGFloat = 0

    private let moonPhases: [MoonPhase] = {
        var phases: [MoonPhase] = []
        for i in 0..<14 {
            let fillPercentage = Double(i) / 13.0
            let color: Color

            switch fillPercentage {
            case 0..<0.15:
                color = .purple
            case 0.15..<0.35:
                color = .red
            case 0.35..<0.5:
                color = .pink
            case 0.5..<0.65:
                color = .orange
            case 0.65..<0.85:
                color = .yellow
            default:
                color = .green
            }

            phases.append(MoonPhase(fillPercentage: fillPercentage, color: color))
        }
        return phases
    }()

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Animation container with dynamic height
                    CircleToLineAnimationView(
                        moonPhases: moonPhases,
                        scrollProgress: scrollProgress
                    )
                    .frame(height: animationHeight)
                    .padding(.top, 60)

                    // Content below
                    VStack(spacing: 20) {
                        Text("PERIOD")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.7))

                        Text("Day 5")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)

                        Text("LOW CHANCE OF PREGNANCY")
                            .font(.caption)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.1))
                            )
                            .foregroundStyle(.white.opacity(0.7))

                        Divider()
                            .background(.white.opacity(0.2))
                            .padding(.vertical, 20)

                        Text("CYCLE DAY 5 OF 28")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))

                        Text("Aimee's Daily Decode")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("If Aimee typically experiences cramps, here's some good news: the pain should be easing up by this time and it should no longer feel as though a demon's fist is grasping their midsection and wringing it like a wet towel.")
                            .font(.body)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button {} label: {
                            HStack {
                                Image(systemName: "face.smiling")
                                Text("Send a reaction")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(.purple.opacity(0.3))
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // Extra content to enable scrolling
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.purple.opacity(0.2))
                                .frame(height: 200)
                                .overlay {
                                    VStack {
                                        Image(systemName: index == 0 ? "brain" : "heart.fill")
                                            .font(.system(size: 60))
                                            .foregroundStyle(.white.opacity(0.3))
                                        Text(index == 0 ? "MIND" : "BODY")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }
                                }
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 40)
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { oldValue, newValue in
                scrollOffset = newValue
                print("Scroll offset: \(newValue), Progress: \(scrollProgress)")
            }

            // Sticky header at the top
            if scrollOffset > 240 {
                VStack(spacing: 0) {
                    CircleToLineAnimationView(
                        moonPhases: moonPhases,
                        scrollProgress: 0
                    )
                    .frame(height: 60)
                    .background(.black)
                }
                .frame(maxWidth: .infinity)
            }

//            // Debug overlay - always visible
//            VStack {
//                HStack {
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Offset: \(String(format: "%.1f", scrollOffset))")
//                        Text("Progress: \(String(format: "%.2f", scrollProgress))")
//                        Text("Height: \(String(format: "%.1f", animationHeight))")
//                    }
//                    Spacer()
//                }
//                .padding(12)
//                .background(.red.opacity(0.9))
//                .foregroundStyle(.white)
//                .font(.system(size: 14, weight: .bold))
//                Spacer()
//            }
        }
    }

    // MARK: - Private Helpers

    /// Calculates the scroll progress based on scroll offset.
    /// - Returns: A value between 0.0 (line) when scrolled down and 1.0 (circle) when at top.
    private var scrollProgress: CGFloat {
        let animationDistance: CGFloat = 240
        // scrollOffset starts at 0 when at the top
        // As we scroll down, scrollOffset increases
        // We want: scrollOffset = 0 -> progress = 1 (circle)
        //          scrollOffset = 240 -> progress = 0 (line)
        let progress = max(0, min(1, 1 - (scrollOffset / animationDistance)))
        return progress
    }

    /// Calculates the dynamic height for the animation container.
    /// - Returns: Height that shrinks when scrolled down, expands when scrolled up.
    private var animationHeight: CGFloat {
        let lineHeight: CGFloat = 0
        let circleHeight: CGFloat = 240
        return lineHeight + (circleHeight - lineHeight) * scrollProgress
    }
}

#Preview {
    MoonPhaseScrollDemoView()
}
