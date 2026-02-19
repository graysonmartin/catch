import SwiftUI
import CoreLocation

@Observable
class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var result: CLLocation?
    var isLoading = false
    var error: String?
    private var pendingRequest = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        isLoading = true
        error = nil
        result = nil

        let status = manager.authorizationStatus
        if status == .notDetermined {
            pendingRequest = true
            manager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else {
            error = "Location access denied. Enable it in Settings."
            isLoading = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if pendingRequest {
            pendingRequest = false
            let status = manager.authorizationStatus
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            } else if status != .notDetermined {
                error = "Location access denied. Enable it in Settings."
                isLoading = false
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        result = locations.first
        isLoading = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error.localizedDescription
        isLoading = false
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
        fetcher.requestLocation()

        Task {
            for _ in 0..<50 {
                try? await Task.sleep(for: .milliseconds(200))
                if let loc = fetcher.result {
                    location.latitude = loc.coordinate.latitude
                    location.longitude = loc.coordinate.longitude
                    hasUsedGPS = true
                    await reverseGeocode(loc)
                    return
                }
                if fetcher.error != nil {
                    return
                }
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
