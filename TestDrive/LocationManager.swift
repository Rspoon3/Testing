import CoreLocation
import UserNotifications
import Foundation

/// Manages location monitoring and geofence-based notifications.
@Observable
final class LocationManager: NSObject {
    private let locationManager = CLLocationManager()
    private let targetLocations: [(coordinate: CLLocationCoordinate2D, identifier: String, description: String)] = [
        (CLLocationCoordinate2D(latitude: 42.73732, longitude: -71.32320), "Location1", "42.73732° N, 71.32320° W"),
        (CLLocationCoordinate2D(latitude: 42.67936, longitude: -71.34238), "Location2", "42.67936° N, 71.34238° W")
    ]

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isMonitoring = false
    var lastError: String?

    // MARK: - Initializer

    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
        setupNotifications()
    }

    // MARK: - Public Helpers

    /// Requests location and notification permissions from the user.
    func requestPermissions() {
        locationManager.requestAlwaysAuthorization()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                DispatchQueue.main.async {
                    self.lastError = "Notification permission error: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Starts monitoring the target location regions.
    func startMonitoring() {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            lastError = "Region monitoring not available"
            return
        }

        for location in targetLocations {
            let region = CLCircularRegion(
                center: location.coordinate,
                radius: 100, // 100 meters
                identifier: location.identifier
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false

            locationManager.startMonitoring(for: region)
        }

        isMonitoring = true
        lastError = nil
    }

    /// Stops monitoring the target location regions.
    func stopMonitoring() {
        for location in targetLocations {
            locationManager.stopMonitoring(for: CLCircularRegion(
                center: location.coordinate,
                radius: 100,
                identifier: location.identifier
            ))
        }
        isMonitoring = false
    }

    // MARK: - Private Helpers

    /// Configures the notification center.
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// Sends a local notification when a target location is reached.
    /// - Parameter locationDescription: The description of the location that was reached.
    private func sendNotification(for locationDescription: String) {
        let content = UNMutableNotificationContent()
        content.title = "Location Reached!"
        content.body = "You've arrived at \(locationDescription)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                DispatchQueue.main.async {
                    self.lastError = "Notification error: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let location = targetLocations.first(where: { $0.identifier == region.identifier }) else { return }
        sendNotification(for: location.description)
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        lastError = nil
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        lastError = "Monitoring failed: \(error.localizedDescription)"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension LocationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
