import SwiftUI

struct SolarSystemView: View {
    @State private var timeMultiplier: Double = 1.0
    @State private var previousMultiplier: Double = 1.0
    @State private var planetTrails: [String: [CGPoint]] = [:]
    @State private var startTime: TimeInterval? = nil
    @State private var isSliderEditing: Bool = false

    var body: some View {
        VStack {
            TimelineView(.animation) { timeline in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                // Use onAppear to set the start time once
                let relativeTime = if let existingStartTime = startTime {
                    now - existingStartTime
                } else {
                    // First render - will set startTime via onAppear below
                    0.0
                }
                
                SolarSystemCanvas(
                    relativeTime: relativeTime,
                    multiplier: timeMultiplier,
                    planetTrails: $planetTrails,
                    isSliderEditing: isSliderEditing
                )
                .border(Color.red)
                .onAppear {
                    if startTime == nil {
                        startTime = now
                    }
                }
            }

            HStack {
                Text("0.5×")
                Slider(value: $timeMultiplier, in: 0.5...30, step: 0.1) {
                    Text("Speed")
                } onEditingChanged: { editing in
                    isSliderEditing = editing
                    
                    if !editing {
                        // When slider editing ends
                        if timeMultiplier != previousMultiplier {
                            // Clear trails only when we've actually changed speeds
                            planetTrails = [:]
                            previousMultiplier = timeMultiplier
                        }
                    } else {
                        // When slider editing begins
                        planetTrails = [:] // Clear trails immediately when starting to edit
                    }
                }
                Text("30×")
            }
            .padding()

            Text("Speed: \(Int(timeMultiplier))×")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct Planet {
    let name: String
    let color: Color
    let size: CGFloat
    let orbitRadius: CGFloat
    let orbitalSpeed: Double
}

struct SolarSystemCanvas: View {
    let relativeTime: TimeInterval
    let multiplier: Double
    @Binding var planetTrails: [String: [CGPoint]]
    let isSliderEditing: Bool

    private let sunSize: CGFloat = 40

    private var planetDefs: [(name: String, color: Color, size: CGFloat, normalizedRadius: CGFloat, orbitalSpeed: Double)] {
        [
            ("Mercury", .gray, 6, 0.10, 4.15),
            ("Venus",   .yellow, 10, 0.18, 1.62),
            ("Earth",   .blue, 12, 0.25, 1.0),
            ("Mars",    .red, 10, 0.33, 0.53),
            ("Jupiter", .orange, 20, 0.45, 0.084),
            ("Saturn",  .brown, 18, 0.55, 0.034),
            ("Uranus",  .cyan, 16, 0.65, 0.011),
            ("Neptune", .purple, 16, 0.75, 0.006)
        ]
    }

    var body: some View {
        Canvas { context, size in
            let sunPosition = CGPoint(x: size.width / 2, y: size.height / 2)
            let sunRect = CGRect(x: sunPosition.x - sunSize / 2,
                                 y: sunPosition.y - sunSize / 2,
                                 width: sunSize, height: sunSize)
            context.fill(Ellipse().path(in: sunRect), with: .color(.orange))
            
            let maxOrbitRadius = min(size.width, size.height) * 0.60

            let planets: [Planet] = planetDefs.map { (name, color, size, normalizedRadius, speed) in
                Planet(name: name,
                       color: color,
                       size: size,
                       orbitRadius: normalizedRadius * maxOrbitRadius,
                       orbitalSpeed: speed)
            }

            for planet in planets {
                let trail = planetTrails[planet.name] ?? []

                // Smooth simulation with interpolated steps per frame
                let frameDelta = 1.0 / 60.0
                let steps = 5
                let timeStep = (frameDelta * multiplier) / Double(steps)
                var positions: [CGPoint] = []

                for i in 0..<steps {
                    let stepTime = (relativeTime - frameDelta) + (Double(i) * timeStep)
                    let angle = stepTime * multiplier * planet.orbitalSpeed
                    let x = sunPosition.x + planet.orbitRadius * cos(angle)
                    let y = sunPosition.y + planet.orbitRadius * sin(angle)
                    positions.append(CGPoint(x: x, y: y))
                }

                // Draw smooth orbit trail with Bézier curves only if not editing slider
                if trail.count > 2 && !isSliderEditing {
                    var path = Path()
                    path.move(to: trail[0])

                    for i in 1..<trail.count - 1 {
                        let mid = midpoint(trail[i], trail[i + 1])
                        path.addQuadCurve(to: mid, control: trail[i])
                    }

                    context.stroke(path,
                                   with: .color(planet.color.opacity(0.5)),
                                   lineWidth: 1)
                }

                // Draw current planet position
                if let current = positions.last {
                    let planetRect = CGRect(x: current.x - planet.size / 2,
                                            y: current.y - planet.size / 2,
                                            width: planet.size, height: planet.size)
                    context.fill(Ellipse().path(in: planetRect), with: .color(planet.color))
                }

                if planet.name == "Earth" {
                    let moonOrbitRadius: CGFloat = 20
                    let moonOrbitalSpeed: Double = 12.0 // faster than Earth's orbit
                    let moonTrailKey = "Moon"
                    let moonTrail = planetTrails[moonTrailKey] ?? []

                    // Compute Earth's position for moon orbit
                    if let earthPosition = positions.last {
                        var moonPositions: [CGPoint] = []

                        for i in 0..<steps {
                            let stepTime = (relativeTime - frameDelta) + (Double(i) * timeStep)
                            let moonAngle = stepTime * multiplier * moonOrbitalSpeed
                            let mx = earthPosition.x + moonOrbitRadius * cos(moonAngle)
                            let my = earthPosition.y + moonOrbitRadius * sin(moonAngle)
                            moonPositions.append(CGPoint(x: mx, y: my))
                        }

                        // Draw moon trail
                        if moonTrail.count > 2 && !isSliderEditing {
                            var moonPath = Path()
                            moonPath.move(to: moonTrail[0])
                            for i in 1..<moonTrail.count - 1 {
                                let mid = midpoint(moonTrail[i], moonTrail[i + 1])
                                moonPath.addQuadCurve(to: mid, control: moonTrail[i])
                            }

                            context.stroke(moonPath,
                                           with: .color(.teal.opacity(0.4)),
                                           lineWidth: 1)
                        }

                        // Draw moon
                        if let moonPosition = moonPositions.last {
                            let moonSize: CGFloat = 6
                            let moonRect = CGRect(x: moonPosition.x - moonSize / 2,
                                                  y: moonPosition.y - moonSize / 2,
                                                  width: moonSize, height: moonSize)
                            context.fill(Ellipse().path(in: moonRect), with: .color(.teal))
                        }

                        // Update moon trail
                        if !isSliderEditing {
                            DispatchQueue.main.async {
                                var updatedMoonTrail = moonTrail
                                updatedMoonTrail.append(contentsOf: moonPositions)
                                if updatedMoonTrail.count > 300 {
                                    updatedMoonTrail.removeFirst(updatedMoonTrail.count - 300)
                                }
                                planetTrails[moonTrailKey] = updatedMoonTrail
                            }
                        }
                    }
                }
                
                // Update trail only if not editing slider
                if !isSliderEditing {
                    DispatchQueue.main.async {
                        var updated = trail
                        updated.append(contentsOf: positions)
                        if updated.count > 300 {
                            updated.removeFirst(updated.count - 300)
                        }
                        planetTrails[planet.name] = updated
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}

#Preview {
    SolarSystemView()
}
