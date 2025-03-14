//
//  AntennaDirectionCalculator.swift
//  Testing
//
//  Created by Ricky on 3/13/25.
//

import Foundation
import CoreLocation

struct AntennaDirectionCalculator {
    
    /// Computes the great-circle distance (in kilometers) and bearing (in degrees) between two coordinate points.
    /// - Parameters:
    ///   - start: The starting location (latitude, longitude).
    ///   - destination: The destination location (latitude, longitude).
    /// - Returns: A tuple containing distance in kilometers and bearing in degrees.
    static func calculateDirection(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> (distance: Double, bearing: Double, compassDirection: String) {
        
        let lat1 = degreesToRadians(start.latitude)
        let lon1 = degreesToRadians(start.longitude)
        let lat2 = degreesToRadians(destination.latitude)
        let lon2 = degreesToRadians(destination.longitude)

        // Haversine formula for distance
        let dLat = lat2 - lat1
        let dLon = lon2 - lon1

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        let earthRadiusKm = 6371.0 // Earth's radius in kilometers
        let distance = earthRadiusKm * c

        // Vincenty's formula for initial bearing
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let initialBearing = atan2(y, x)
        let bearingDegrees = radiansToDegrees(initialBearing).truncatingRemainder(dividingBy: 360)
        
        let compassDirection = bearingToCompass(bearingDegrees)
        
        return (distance, bearingDegrees >= 0 ? bearingDegrees : bearingDegrees + 360, compassDirection)
    }
    
    /// Converts degrees to radians.
    private static func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180
    }

    /// Converts radians to degrees.
    private static func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180 / .pi
    }
    
    /// Converts a bearing angle into a compass direction.
    private static func bearingToCompass(_ bearing: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((bearing / 22.5) + 0.5) % 16
        return directions[index]
    }
}
