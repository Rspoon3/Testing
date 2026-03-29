import MapKit
import CoreLocation
import UIKit
import os

/// Takes map snapshots of workout routes using MKMapSnapshotter, with detailed timing benchmarks.
final class MapSnapshotService: Sendable {
    private let logger = Logger(subsystem: "com.rspoon3.TestDrive", category: "MapSnapshot")

    /// Configuration for snapshot generation.
    struct SnapshotConfig: Sendable {
        var size: CGSize = CGSize(width: 150, height: 150)
        var mapType: MKMapType = .mutedStandard
        var lineWidth: CGFloat = 2
        var strokeColor: UIColor = .systemBlue
    }

    /// Generates a map snapshot for a set of locations, returning the image and timing data.
    /// - Parameters:
    ///   - locations: The route locations to render.
    ///   - config: Configuration for the snapshot.
    /// - Returns: A `SnapshotResult` with the image and timing breakdown.
    func generateSnapshot(
        for locations: [CLLocation],
        config: SnapshotConfig = SnapshotConfig()
    ) async throws -> SnapshotResult {
        let startTime = ContinuousClock.now

        guard locations.count >= 2 else {
            throw SnapshotError.insufficientLocations
        }

        let allCoordinates = locations.map(\.coordinate)
        let coordinates = Self.downsample(allCoordinates, maxPoints: 120)

        // Calculate the region
        let regionStart = ContinuousClock.now
        let region = Self.region(for: coordinates)
        let regionDuration = regionStart.duration(to: .now)

        // Configure the snapshotter
        let configStart = ContinuousClock.now
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = config.size
        options.mapType = config.mapType
        options.traitCollection = UITraitCollection(userInterfaceStyle: .light)
        let configDuration = configStart.duration(to: .now)

        // Take the snapshot
        let snapshotStart = ContinuousClock.now
        let snapshotter = MKMapSnapshotter(options: options)
        let snapshot = try await snapshotter.start()
        let snapshotDuration = snapshotStart.duration(to: .now)

        // Draw the route overlay
        let drawStart = ContinuousClock.now
        let image = Self.drawRoute(
            on: snapshot,
            coordinates: coordinates,
            size: config.size,
            lineWidth: config.lineWidth,
            strokeColor: config.strokeColor
        )
        let drawDuration = drawStart.duration(to: .now)

        let totalDuration = startTime.duration(to: .now)

        let timing = SnapshotTiming(
            regionCalculation: regionDuration,
            configuration: configDuration,
            snapshotGeneration: snapshotDuration,
            routeDrawing: drawDuration,
            total: totalDuration
        )

        logger.info("""
        Snapshot complete — \
        total: \(timing.totalMs, format: .fixed(precision: 1))ms, \
        snapshot: \(timing.snapshotGenerationMs, format: .fixed(precision: 1))ms, \
        drawing: \(timing.routeDrawingMs, format: .fixed(precision: 1))ms, \
        points: \(locations.count)
        """)

        return SnapshotResult(image: image, timing: timing, locationCount: locations.count)
    }

    // MARK: - Private Helpers

    /// Reduces coordinate count by taking evenly spaced samples, always keeping first and last.
    private static func downsample(_ coordinates: [CLLocationCoordinate2D], maxPoints: Int) -> [CLLocationCoordinate2D] {
        guard coordinates.count > maxPoints else { return coordinates }
        let step = Double(coordinates.count - 1) / Double(maxPoints - 1)
        return (0..<maxPoints).map { i in
            coordinates[min(Int(Double(i) * step), coordinates.count - 1)]
        }
    }

    /// Calculates a map region that fits all coordinates with padding.
    private static func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    /// Draws the route polyline on top of the map snapshot image.
    private static func drawRoute(
        on snapshot: MKMapSnapshotter.Snapshot,
        coordinates: [CLLocationCoordinate2D],
        size: CGSize,
        lineWidth: CGFloat,
        strokeColor: UIColor
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            snapshot.image.draw(at: .zero)

            let path = UIBezierPath()
            for (index, coordinate) in coordinates.enumerated() {
                let point = snapshot.point(for: coordinate)
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }

            context.cgContext.setStrokeColor(strokeColor.cgColor)
            context.cgContext.setLineWidth(lineWidth)
            context.cgContext.setLineCap(.round)
            context.cgContext.setLineJoin(.round)
            context.cgContext.addPath(path.cgPath)
            context.cgContext.strokePath()
        }
    }
}

// MARK: - Supporting Types

/// Timing breakdown for a single snapshot operation.
struct SnapshotTiming: Sendable {
    let regionCalculation: Duration
    let configuration: Duration
    let snapshotGeneration: Duration
    let routeDrawing: Duration
    let total: Duration

    var regionCalculationMs: Double { regionCalculation.milliseconds }
    var configurationMs: Double { configuration.milliseconds }
    var snapshotGenerationMs: Double { snapshotGeneration.milliseconds }
    var routeDrawingMs: Double { routeDrawing.milliseconds }
    var totalMs: Double { total.milliseconds }
}

/// Result of a single snapshot operation.
struct SnapshotResult: Sendable {
    let image: UIImage
    let timing: SnapshotTiming
    let locationCount: Int
}

/// Errors from the snapshot service.
enum SnapshotError: LocalizedError {
    case insufficientLocations

    var errorDescription: String? {
        switch self {
        case .insufficientLocations:
            "Need at least 2 locations to generate a route snapshot."
        }
    }
}

// MARK: - Duration Extension

extension Duration {
    /// Converts the duration to milliseconds as a Double.
    var milliseconds: Double {
        let (seconds, attoseconds) = components
        return Double(seconds) * 1000 + Double(attoseconds) / 1_000_000_000_000_000
    }
}
