import Foundation
import CoreLocation
import Combine

/// One-shot current-location provider used as the pickup point for ride
/// links. The Info.plist has always declared
/// NSLocationWhenInUseUsageDescription; this wires it up (the pre-revival
/// build declared the permission but never requested a location, and
/// silently sent pickup coordinates 0,0 to Uber).
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var current: RideLatLng?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Ask for authorization if needed and take a single location fix.
    /// Safe to call repeatedly; a no-op once a fix exists or when denied.
    func requestCurrentLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break // denied/restricted: links simply omit the pickup point
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse
            || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            current = RideLatLng(lat: loc.coordinate.latitude, lng: loc.coordinate.longitude)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Non-fatal: links fall back to omitting the pickup point.
    }
}
