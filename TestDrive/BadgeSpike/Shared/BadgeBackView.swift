//
//  BadgeBackView.swift
//  TestDrive
//

import SwiftUI

/// The reverse of the medallion: the landmark's name and the date it was earned.
///
/// Worth having in a spike about spinning, because a back face is the thing that
/// makes a full rotation *mean* something — without it, turning the badge past 90°
/// just reveals mirrored artwork and the spin reads as a bug. It is also where the
/// three flat approaches diverge from the two 3D ones: here it is a swapped view,
/// there it is a second textured quad.
struct BadgeBackView: View {
    private let badge: Badge

    // MARK: - Initializer

    /// Creates the badge reverse.
    /// - Parameter badge: The badge to draw.
    init(badge: Badge) {
        self.badge = badge
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            blank
            engravedRing
            inscription
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Private Views

    /// The unstruck side: the same metal, but flatter, with the light coming from
    /// the opposite corner so the reverse never looks like the front.
    private var blank: some View {
        Circle()
            .fill(
                AngularGradient(
                    colors: badge.finish.faceColors.reversed()
                        + badge.finish.faceColors,
                    center: .center
                )
            )
            .overlay {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.22), .clear, .black.opacity(0.5)],
                            center: .init(x: 0.68, y: 0.72),
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
            }
    }

    /// A double ring, so the reverse is distinguishable at a glance while spinning.
    private var engravedRing: some View {
        ZStack {
            Circle()
                .strokeBorder(badge.finish.engravingColor.opacity(0.5), lineWidth: 2)
                .padding(12)

            Circle()
                .strokeBorder(badge.finish.engravingColor.opacity(0.3), lineWidth: 1)
                .padding(20)
        }
    }

    /// The struck text.
    private var inscription: some View {
        VStack(spacing: 10) {
            Text(badge.title.uppercased())
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(3)

            Rectangle()
                .frame(width: 60, height: 1)
                .opacity(0.45)

            VStack(spacing: 1) {
                Text("EARNED")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(2.5)
                    .opacity(0.75)

                Text(badge.formattedEarnedDate)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
            }
        }
        .foregroundStyle(badge.finish.engravingColor)
        // The same one-pixel light offset the front uses, so both sides read as cut
        // into metal rather than printed on it.
        .shadow(color: .white.opacity(0.45), radius: 0, y: 1)
        .padding(38)
    }
}

extension BadgeBackView {

    // MARK: - Public Helpers

    /// Rasterizes the reverse for use as a RealityKit texture.
    /// - Parameters:
    ///   - badge: The badge to draw.
    ///   - size: The texture's pixel size.
    /// - Returns: The rendered reverse, or `nil` if rasterization failed.
    @MainActor
    static func renderedBack(for badge: Badge, size: CGFloat = 512) -> CGImage? {
        let renderer = ImageRenderer(
            content: BadgeBackView(badge: badge)
                .badgeCanvas(scaledTo: size)
                .background(.black)
        )
        renderer.scale = 1
        return renderer.cgImage
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(Badge.samples.prefix(2)) { badge in
            HStack(spacing: 16) {
                BadgeFaceView(badge: badge)
                BadgeBackView(badge: badge)
            }
            .frame(height: 160)
        }
    }
    .padding()
}
