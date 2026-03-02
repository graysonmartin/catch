import SwiftUI
import SwiftData
import MapKit

private enum MapConfig {
    static let clusterZoomSpan: CLLocationDegrees = 0.003
    static let spiderfyThreshold: CLLocationDegrees = 0.005
    static let spiderfyRadiusMultiplier: Double = 0.08
    static let overlapThreshold: CLLocationDegrees = 0.001
    static let maxSpiderfyCount = 9
    static let photoComparisonPrefixSize = 64

    static let clusterReuseID = "cluster"
    static let overflowReuseID = "overflow"
    static let catPinReuseID = "catPin"
}

// MARK: - Snapshot for change detection

struct PinSnapshot: Equatable {
    let id: String
    let name: String?
    let latitude: Double?
    let longitude: Double?
    let photoCount: Int
    let firstPhotoPrefix: Data?

    init(pin: MapPin) {
        switch pin {
        case .local(let cat):
            self.id = "local-\(cat.persistentModelID)"
            self.name = cat.name
            self.latitude = cat.location.latitude
            self.longitude = cat.location.longitude
            self.photoCount = cat.photos.count
            self.firstPhotoPrefix = cat.photos.first.map { Data($0.prefix(MapConfig.photoComparisonPrefixSize)) }
        case .remote(let encounter, let cat, _):
            self.id = "remote-\(encounter.recordName)"
            self.name = cat?.name
            self.latitude = encounter.locationLatitude
            self.longitude = encounter.locationLongitude
            self.photoCount = cat?.photos.count ?? 0
            self.firstPhotoPrefix = cat?.photos.first.map { Data($0.prefix(MapConfig.photoComparisonPrefixSize)) }
        }
    }
}

// MARK: - UIKit MKMapView with clustering

struct ClusterMapView: UIViewRepresentable {
    let pins: [MapPin]
    let onSelectPin: (MapPin) -> Void
    let onSelectCluster: ([MapPin]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectPin: onSelectPin, onSelectCluster: onSelectCluster)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let snapshot = pins.map { PinSnapshot(pin: $0) }
        guard snapshot != context.coordinator.lastSnapshot else { return }
        context.coordinator.lastSnapshot = snapshot
        context.coordinator.isSpiderfied = false
        context.coordinator.isUpdatingRegion = false

        let old = mapView.annotations.filter { $0 is CatAnnotation || $0 is OverflowAnnotation || $0 is MKClusterAnnotation }
        mapView.removeAnnotations(old)
        context.coordinator.allPins = pins

        var annotations: [CatAnnotation] = []
        for pin in pins {
            guard let coordinate = pin.coordinate else { continue }
            let a = CatAnnotation()
            a.pin = pin
            a.title = pin.displayName
            a.coordinate = coordinate
            annotations.append(a)
        }

        mapView.addAnnotations(annotations)

        if context.coordinator.needsInitialZoom {
            context.coordinator.needsInitialZoom = false
            mapView.showAnnotations(annotations, animated: false)
        }
    }

    // MARK: Coordinator

    class Coordinator: NSObject, MKMapViewDelegate {
        let onSelectPin: (MapPin) -> Void
        let onSelectCluster: ([MapPin]) -> Void
        var lastSnapshot: [PinSnapshot] = []
        var needsInitialZoom = true
        var allPins: [MapPin] = []
        var isSpiderfied = false
        var isUpdatingRegion = false

        init(onSelectPin: @escaping (MapPin) -> Void, onSelectCluster: @escaping ([MapPin]) -> Void) {
            self.onSelectPin = onSelectPin
            self.onSelectCluster = onSelectCluster
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
            if let cluster = annotation as? MKClusterAnnotation {
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: MapConfig.clusterReuseID) as? CatClusterView)
                    ?? CatClusterView(annotation: cluster, reuseIdentifier: MapConfig.clusterReuseID)
                view.annotation = cluster
                return view
            }
            if let overflow = annotation as? OverflowAnnotation {
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: MapConfig.overflowReuseID) as? OverflowAnnotationView)
                    ?? OverflowAnnotationView(annotation: overflow, reuseIdentifier: MapConfig.overflowReuseID)
                view.annotation = overflow
                return view
            }
            if let catAnnotation = annotation as? CatAnnotation {
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: MapConfig.catPinReuseID) as? CatAnnotationView)
                    ?? CatAnnotationView(annotation: catAnnotation, reuseIdentifier: MapConfig.catPinReuseID)
                view.annotation = catAnnotation
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            mapView.deselectAnnotation(view.annotation, animated: false)

            if let cluster = view.annotation as? MKClusterAnnotation {
                let region = MKCoordinateRegion(
                    center: cluster.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: MapConfig.clusterZoomSpan, longitudeDelta: MapConfig.clusterZoomSpan)
                )
                mapView.setRegion(region, animated: true)
            } else if let overflow = view.annotation as? OverflowAnnotation {
                onSelectCluster(overflow.overflowPins)
            } else if let catAnnotation = view.annotation as? CatAnnotation, let pin = catAnnotation.pin {
                onSelectPin(pin)
            }
        }

        // MARK: Spiderfy on zoom

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard !isUpdatingRegion else { return }
            let span = mapView.region.span
            let zoomedIn = span.latitudeDelta < MapConfig.spiderfyThreshold

            if zoomedIn && !isSpiderfied {
                spiderfy(mapView)
            } else if !zoomedIn && isSpiderfied {
                unspiderfy(mapView)
            }
        }

        private let maxSpiderfyCount = MapConfig.maxSpiderfyCount

        private func spiderfy(_ mapView: MKMapView) {
            isUpdatingRegion = true
            isSpiderfied = true

            let annotations = mapView.annotations.compactMap { $0 as? CatAnnotation }
            let clusterAnnotations = mapView.annotations.compactMap { $0 as? MKClusterAnnotation }

            var allAnnotations: [CatAnnotation] = annotations
            for cluster in clusterAnnotations {
                for member in cluster.memberAnnotations {
                    if let catAnn = member as? CatAnnotation, !allAnnotations.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(catAnn) }) {
                        allAnnotations.append(catAnn)
                    }
                }
            }

            mapView.removeAnnotations(mapView.annotations.filter { $0 is CatAnnotation || $0 is MKClusterAnnotation })

            let groups = findOverlappingGroups(allAnnotations)
            let radius = mapView.region.span.latitudeDelta * MapConfig.spiderfyRadiusMultiplier
            var hiddenAnnotations: Set<ObjectIdentifier> = []

            for group in groups {
                let centerLat = group.map(\.coordinate.latitude).reduce(0, +) / Double(group.count)
                let centerLng = group.map(\.coordinate.longitude).reduce(0, +) / Double(group.count)

                // Local cats with more encounters surface first; remote pins sort to the end
                let sorted = group.sorted { ($0.pin?.encounterSortWeight ?? 0) > ($1.pin?.encounterSortWeight ?? 0) }
                let visible = Array(sorted.prefix(maxSpiderfyCount))
                let overflow = Array(sorted.dropFirst(maxSpiderfyCount))

                for (i, annotation) in visible.enumerated() {
                    annotation.originalCoordinate = annotation.coordinate
                    annotation.isSpread = true
                    let angle = (2 * .pi * Double(i)) / Double(visible.count) - .pi / 2
                    annotation.coordinate = CLLocationCoordinate2D(
                        latitude: centerLat + radius * cos(angle),
                        longitude: centerLng + radius * sin(angle)
                    )
                }

                for ann in overflow {
                    ann.originalCoordinate = ann.coordinate
                    ann.isSpread = true
                    hiddenAnnotations.insert(ObjectIdentifier(ann))
                }

                if !overflow.isEmpty {
                    let overflowPin = OverflowAnnotation()
                    overflowPin.coordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
                    overflowPin.overflowPins = overflow.compactMap(\.pin)
                    mapView.addAnnotation(overflowPin)
                }
            }

            for annotation in allAnnotations where !hiddenAnnotations.contains(ObjectIdentifier(annotation)) {
                mapView.addAnnotation(annotation)
            }

            DispatchQueue.main.async {
                for annotation in allAnnotations where annotation.isSpread && !hiddenAnnotations.contains(ObjectIdentifier(annotation)) {
                    if let view = mapView.view(for: annotation) as? CatAnnotationView {
                        view.clusteringIdentifier = nil
                    }
                }
                self.isUpdatingRegion = false
            }
        }

        private func unspiderfy(_ mapView: MKMapView) {
            isUpdatingRegion = true
            isSpiderfied = false

            let overflows = mapView.annotations.compactMap { $0 as? OverflowAnnotation }
            mapView.removeAnnotations(overflows)

            let annotations = mapView.annotations.compactMap { $0 as? CatAnnotation }
            mapView.removeAnnotations(annotations)

            var restored: [CatAnnotation] = []
            for pin in allPins {
                guard let coordinate = pin.coordinate else { continue }
                let a = CatAnnotation()
                a.pin = pin
                a.title = pin.displayName
                a.coordinate = coordinate
                restored.append(a)
            }

            mapView.addAnnotations(restored)

            DispatchQueue.main.async {
                for annotation in restored {
                    if let view = mapView.view(for: annotation) as? CatAnnotationView {
                        view.clusteringIdentifier = AnnotationLayout.clusteringID
                    }
                }
                self.isUpdatingRegion = false
            }
        }

        private func findOverlappingGroups(_ annotations: [CatAnnotation]) -> [[CatAnnotation]] {
            var used = Set<ObjectIdentifier>()
            var groups: [[CatAnnotation]] = []

            for annotation in annotations {
                let id = ObjectIdentifier(annotation)
                if used.contains(id) { continue }

                var group = [annotation]
                used.insert(id)

                for other in annotations {
                    let otherId = ObjectIdentifier(other)
                    if used.contains(otherId) { continue }
                    let dLat = abs(annotation.coordinate.latitude - other.coordinate.latitude)
                    let dLng = abs(annotation.coordinate.longitude - other.coordinate.longitude)
                    if dLat < MapConfig.overlapThreshold && dLng < MapConfig.overlapThreshold {
                        group.append(other)
                        used.insert(otherId)
                    }
                }

                if group.count > 1 {
                    groups.append(group)
                }
            }
            return groups
        }
    }
}
