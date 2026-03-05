import SwiftUI
import MapKit
import CatchCore

/// A map with a fixed center pin. User pans the map to move the location.
/// On pan end, reverse-geocodes the center and updates the binding.
/// Shows a neutral zoomed-out view when no coordinates are set.
struct LocationMapPreview: UIViewRepresentable {
    @Binding var location: Location

    /// Called when the user pans the map to a new position.
    var onLocationChanged: ((Location) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.showsUserLocation = false
        map.layer.cornerRadius = CatchTheme.cornerRadius
        map.clipsToBounds = true

        if let coordinate = coordinate {
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            map.setRegion(region, animated: false)
        }

        // Fixed pin overlay in the center of the map
        let pin = UIImageView(image: UIImage(systemName: "mappin.circle.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 36, weight: .medium))
            .withTintColor(CatchTheme.primaryUIColor, renderingMode: .alwaysOriginal))
        pin.translatesAutoresizingMaskIntoConstraints = false
        pin.contentMode = .scaleAspectFit
        map.addSubview(pin)
        NSLayoutConstraint.activate([
            pin.centerXAnchor.constraint(equalTo: map.centerXAnchor),
            pin.centerYAnchor.constraint(equalTo: map.centerYAnchor, constant: -18)
        ])
        context.coordinator.pinView = pin

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        guard let coordinate = coordinate else { return }
        guard !context.coordinator.isPanning else { return }

        let current = map.centerCoordinate
        let moved = abs(current.latitude - coordinate.latitude) > 0.0001
            || abs(current.longitude - coordinate.longitude) > 0.0001
        if moved {
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            map.setRegion(region, animated: true)
        }
    }

    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = location.latitude, let lng = location.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    // MARK: - Coordinator (no @MainActor — matches ClusterMapView pattern)

    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: LocationMapPreview
        var pinView: UIImageView?
        var isPanning = false
        private var geocodeTask: Task<Void, Never>?

        init(parent: LocationMapPreview) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            if mapView.isUserInteracting {
                isPanning = true
                UIView.animate(withDuration: 0.15) {
                    self.pinView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                        .translatedBy(x: 0, y: -4)
                }
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard isPanning else { return }
            isPanning = false

            UIView.animate(withDuration: 0.15) {
                self.pinView?.transform = .identity
            }

            let center = mapView.centerCoordinate
            reverseGeocodeAndUpdate(center)
        }

        private func reverseGeocodeAndUpdate(_ coordinate: CLLocationCoordinate2D) {
            geocodeTask?.cancel()
            geocodeTask = Task { @MainActor [parent] in
                let clLocation = CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                let name = await reverseGeocodeName(for: clLocation)
                guard !Task.isCancelled else { return }
                let newLocation = Location(
                    name: name,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                parent.location = newLocation
                parent.onLocationChanged?(newLocation)
            }
        }

        private func reverseGeocodeName(for location: CLLocation) async -> String {
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let place = placemarks.first {
                    return LocationNameBuilder.buildName(
                        name: place.name,
                        locality: place.locality,
                        administrativeArea: place.administrativeArea
                    )
                }
            } catch {
                // Geocoding failed — coordinates still valid
            }
            return ""
        }
    }
}

// MARK: - MKMapView user interaction detection

private extension MKMapView {
    var isUserInteracting: Bool {
        subviews.first?.gestureRecognizers?.contains(where: {
            $0.state == .began || $0.state == .changed
        }) ?? false
    }
}
