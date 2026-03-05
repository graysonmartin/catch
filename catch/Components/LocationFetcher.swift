import SwiftUI
import CoreLocation
import CatchCore

@MainActor
@Observable
class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var isFetchingLocation = false
    var error: String?

    private var authContinuation: CheckedContinuation<Bool, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, any Error>?

    enum FetchError: LocalizedError {
        case denied
        case timeout

        var errorDescription: String? {
            switch self {
            case .denied: return CatchStrings.Components.locationDenied
            case .timeout: return CatchStrings.Components.locationTimeout
            }
        }
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Fetches the current GPS location and reverse-geocodes it into a `Location`.
    /// The `isFetchingLocation` flag remains `true` until geocoding completes.
    func fetchCurrentLocation() async throws -> Location {
        isFetchingLocation = true
        error = nil

        do {
            let clLocation = try await requestCLLocation()
            let name = await reverseGeocodeName(for: clLocation)
            isFetchingLocation = false
            return Location(
                name: name,
                latitude: clLocation.coordinate.latitude,
                longitude: clLocation.coordinate.longitude
            )
        } catch {
            isFetchingLocation = false
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - Private Helpers

    private func requestCLLocation() async throws -> CLLocation {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            let authorized = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
                self.authContinuation = cont
                self.manager.requestWhenInUseAuthorization()
            }
            guard authorized else {
                error = FetchError.denied.errorDescription
                throw FetchError.denied
            }
        } else if status != .authorizedWhenInUse && status != .authorizedAlways {
            error = FetchError.denied.errorDescription
            throw FetchError.denied
        }

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CLLocation, any Error>) in
            self.locationContinuation = cont
            self.manager.requestLocation()
        }
    }

    private func reverseGeocodeName(for location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let place = placemarks.first {
                return LocationNameBuilder.buildName(from: place)
            }
        } catch {
            // Geocoding failed — return empty name, coordinates are still valid
        }
        return ""
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            guard let cont = authContinuation else { return }
            let status = manager.authorizationStatus
            guard status != .notDetermined else { return }

            authContinuation = nil
            cont.resume(returning: status == .authorizedWhenInUse || status == .authorizedAlways)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            guard let cont = locationContinuation, let loc = locations.first else { return }
            locationContinuation = nil
            cont.resume(returning: loc)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            guard let cont = locationContinuation else { return }
            locationContinuation = nil
            cont.resume(throwing: error)
        }
    }
}

// MARK: - CLPlacemark Convenience

private extension LocationNameBuilder {

    static func buildName(from placemark: CLPlacemark) -> String {
        buildName(
            name: placemark.name,
            locality: placemark.locality,
            administrativeArea: placemark.administrativeArea
        )
    }
}
