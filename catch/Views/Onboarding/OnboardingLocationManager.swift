import CoreLocation

/// Lightweight location-permission manager used during onboarding.
@Observable
class OnboardingLocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var hasRequested = false
    var wasGranted = false

    override init() {
        super.init()
        manager.delegate = self
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            hasRequested = true
            wasGranted = true
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status != .notDetermined {
            hasRequested = true
            wasGranted = status == .authorizedWhenInUse || status == .authorizedAlways
        }
    }
}
