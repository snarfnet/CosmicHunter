import Foundation
import CoreLocation

/// Reads altitude to show an approximate cosmic-ray intensity hint.
/// Cosmic-ray flux roughly doubles every ~1500 m of altitude, so higher = more hits.
/// Location stays on-device and is optional — denying it just hides the altitude hint.
final class AltitudeService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var altitude: Double?      // metres
    @Published var denied = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            denied = true
        default:
            manager.startUpdatingLocation()
        }
    }

    /// Relative flux vs sea level (~1.0 at 0 m, ~2x per 1500 m).
    var relativeFlux: Double? {
        guard let a = altitude else { return nil }
        return pow(2.0, max(0, a) / 1500.0)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            denied = false
            manager.startUpdatingLocation()
        case .denied, .restricted:
            denied = true
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async { self.altitude = loc.altitude }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    func loadDemoState() {
        altitude = 634
    }
}
