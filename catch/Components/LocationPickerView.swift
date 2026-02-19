import SwiftUI
import CoreLocation

@Observable
class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var isLoading = false
    var error: String?

    private var authContinuation: CheckedContinuation<Bool, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, any Error>?

    enum FetchError: LocalizedError {
        case denied
        case timeout

        var errorDescription: String? {
            switch self {
            case .denied: return "Location access denied. Enable it in Settings."
            case .timeout: return "Location request timed out. Try again."
            }
        }
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func fetchLocation() async throws -> CLLocation {
        isLoading = true
        error = nil

        let status = manager.authorizationStatus
        if status == .notDetermined {
            let authorized = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
                self.authContinuation = cont
                self.manager.requestWhenInUseAuthorization()
            }
            guard authorized else {
                isLoading = false
                error = FetchError.denied.errorDescription
                throw FetchError.denied
            }
        } else if status != .authorizedWhenInUse && status != .authorizedAlways {
            isLoading = false
            error = FetchError.denied.errorDescription
            throw FetchError.denied
        }

        do {
            let location = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CLLocation, any Error>) in
                self.locationContinuation = cont
                self.manager.requestLocation()
            }
            isLoading = false
            return location
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            throw error
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let cont = authContinuation else { return }
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }

        authContinuation = nil
        cont.resume(returning: status == .authorizedWhenInUse || status == .authorizedAlways)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let cont = locationContinuation, let loc = locations.first else { return }
        locationContinuation = nil
        cont.resume(returning: loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let cont = locationContinuation else { return }
        locationContinuation = nil
        cont.resume(throwing: error)
    }
}

struct LocationPickerView: View {
    @Binding var location: Location

    @State private var fetcher = LocationFetcher()
    @State private var hasUsedGPS = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                fetchCurrentLocation()
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text(fetcher.isLoading ? "Getting Location..." : "Use Current Location")
                }
                .font(.subheadline)
                .foregroundStyle(CatchTheme.primary)
            }
            .disabled(fetcher.isLoading)

            if hasUsedGPS, location.hasCoordinates {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(location.name.isEmpty ? "Coordinates saved" : location.name)
                        .font(.caption)
                        .foregroundStyle(CatchTheme.textSecondary)
                }
            }

            if let error = fetcher.error {
                HStack(spacing: 4) {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                    if error.contains("Settings") {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Open Settings")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(CatchTheme.primary)
                        }
                    }
                }
            }

            TextField("Or type location name", text: $location.name)
                .onChange(of: location.name) {
                    if !hasUsedGPS {
                        location.latitude = nil
                        location.longitude = nil
                    }
                    hasUsedGPS = false
                }
        }
    }

    private func fetchCurrentLocation() {
        Task {
            do {
                let loc = try await fetcher.fetchLocation()
                location.latitude = loc.coordinate.latitude
                location.longitude = loc.coordinate.longitude
                hasUsedGPS = true
                await reverseGeocode(loc)
            } catch {
                // Error already set on fetcher by fetchLocation()
            }
        }
    }

    private func reverseGeocode(_ loc: CLLocation) async {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(loc)
            if let place = placemarks.first {
                let parts = [place.name, place.locality, place.administrativeArea].compactMap { $0 }
                if !parts.isEmpty {
                    location.name = parts.joined(separator: ", ")
                    hasUsedGPS = true
                }
            }
        } catch {
            // Keep coordinates even if geocoding fails
        }
    }
}
