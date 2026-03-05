import SwiftUI
import MapKit
import CatchCore

/// A compact map preview with a draggable pin for adjusting a location.
/// On drag end, reverse-geocodes the new position and updates the binding.
struct LocationMapPreview: UIViewRepresentable {
    @Binding var location: Location

    /// Called when the user drags the pin to a new position.
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
            let annotation = DraggableAnnotation(coordinate: coordinate)
            map.addAnnotation(annotation)
            context.coordinator.annotation = annotation
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            map.setRegion(region, animated: false)
        }

        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        guard let coordinate = coordinate else { return }

        // Skip map updates while user is dragging
        guard !context.coordinator.isDragging else { return }

        if let annotation = context.coordinator.annotation {
            let current = annotation.coordinate
            let moved = abs(current.latitude - coordinate.latitude) > 0.0001
                || abs(current.longitude - coordinate.longitude) > 0.0001
            if moved {
                annotation.coordinate = coordinate
                let region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
                map.setRegion(region, animated: true)
            }
        } else {
            let annotation = DraggableAnnotation(coordinate: coordinate)
            map.addAnnotation(annotation)
            context.coordinator.annotation = annotation
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

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, MKMapViewDelegate {
        private let parent: LocationMapPreview
        fileprivate var annotation: DraggableAnnotation?
        var isDragging = false

        init(parent: LocationMapPreview) {
            self.parent = parent
        }

        func mapView(
            _ mapView: MKMapView,
            viewFor annotation: any MKAnnotation
        ) -> MKAnnotationView? {
            guard annotation is DraggableAnnotation else { return nil }

            let identifier = "DraggablePin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)

            view.isDraggable = true
            view.canShowCallout = false
            view.markerTintColor = CatchTheme.primaryUIColor
            view.glyphImage = UIImage(systemName: "mappin")
            view.animatesWhenAdded = true
            view.annotation = annotation
            return view
        }

        func mapView(
            _ mapView: MKMapView,
            annotationView view: MKAnnotationView,
            didChange newState: MKAnnotationView.DragState,
            fromOldState oldState: MKAnnotationView.DragState
        ) {
            switch newState {
            case .starting:
                isDragging = true
            case .ending, .canceling:
                isDragging = false
                guard let coordinate = view.annotation?.coordinate else { return }
                reverseGeocodeAndUpdate(coordinate)
            default:
                break
            }
        }

        private func reverseGeocodeAndUpdate(_ coordinate: CLLocationCoordinate2D) {
            Task { @MainActor in
                let clLocation = CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                let name = await Self.reverseGeocodeName(for: clLocation)
                let newLocation = Location(
                    name: name,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                parent.location = newLocation
                parent.onLocationChanged?(newLocation)
            }
        }

        private static func reverseGeocodeName(for location: CLLocation) async -> String {
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

// MARK: - Draggable Annotation

fileprivate final class DraggableAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}
