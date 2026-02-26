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

struct CatSnapshot: Equatable {
    let id: PersistentIdentifier
    let name: String?
    let latitude: Double?
    let longitude: Double?
    let photoCount: Int
    let firstPhotoPrefix: Data?

    init(cat: Cat) {
        self.id = cat.persistentModelID
        self.name = cat.name
        self.latitude = cat.location.latitude
        self.longitude = cat.location.longitude
        self.photoCount = cat.photos.count
        self.firstPhotoPrefix = cat.photos.first.map { Data($0.prefix(MapConfig.photoComparisonPrefixSize)) }
    }
}

// MARK: - UIKit MKMapView with clustering

struct ClusterMapView: UIViewRepresentable {
    let cats: [Cat]
    let onSelectCat: (Cat) -> Void
    let onSelectCluster: ([Cat]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectCat: onSelectCat, onSelectCluster: onSelectCluster)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let snapshot = cats.map { CatSnapshot(cat: $0) }
        guard snapshot != context.coordinator.lastSnapshot else { return }
        context.coordinator.lastSnapshot = snapshot
        context.coordinator.isSpiderfied = false
        context.coordinator.isUpdatingRegion = false

        // Remove all custom annotations
        let old = mapView.annotations.filter { $0 is CatAnnotation || $0 is OverflowAnnotation || $0 is MKClusterAnnotation }
        mapView.removeAnnotations(old)
        context.coordinator.allCats = cats

        var annotations: [CatAnnotation] = []
        for cat in cats {
            guard let lat = cat.location.latitude, let lng = cat.location.longitude else { continue }
            let a = CatAnnotation()
            a.cat = cat
            a.title = cat.displayName
            a.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
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
        let onSelectCat: (Cat) -> Void
        let onSelectCluster: ([Cat]) -> Void
        var lastSnapshot: [CatSnapshot] = []
        var needsInitialZoom = true
        var allCats: [Cat] = []
        var isSpiderfied = false
        var isUpdatingRegion = false

        init(onSelectCat: @escaping (Cat) -> Void, onSelectCluster: @escaping ([Cat]) -> Void) {
            self.onSelectCat = onSelectCat
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
                // Zoom in toward the cluster to trigger spiderfy
                let region = MKCoordinateRegion(
                    center: cluster.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: MapConfig.clusterZoomSpan, longitudeDelta: MapConfig.clusterZoomSpan)
                )
                mapView.setRegion(region, animated: true)
            } else if let overflow = view.annotation as? OverflowAnnotation {
                onSelectCluster(overflow.overflowCats)
            } else if let catAnnotation = view.annotation as? CatAnnotation, let cat = catAnnotation.cat {
                onSelectCat(cat)
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

            // Remove all cat annotations and re-add WITHOUT clustering
            let annotations = mapView.annotations.compactMap { $0 as? CatAnnotation }
            let clusterAnnotations = mapView.annotations.compactMap { $0 as? MKClusterAnnotation }

            // Gather all CatAnnotations (visible + inside clusters)
            var allAnnotations: [CatAnnotation] = annotations
            for cluster in clusterAnnotations {
                for member in cluster.memberAnnotations {
                    if let catAnn = member as? CatAnnotation, !allAnnotations.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(catAnn) }) {
                        allAnnotations.append(catAnn)
                    }
                }
            }

            // Remove everything
            mapView.removeAnnotations(mapView.annotations.filter { $0 is CatAnnotation || $0 is MKClusterAnnotation })

            let groups = findOverlappingGroups(allAnnotations)
            let radius = mapView.region.span.latitudeDelta * MapConfig.spiderfyRadiusMultiplier
            var hiddenAnnotations: Set<ObjectIdentifier> = []

            for group in groups {
                let centerLat = group.map(\.coordinate.latitude).reduce(0, +) / Double(group.count)
                let centerLng = group.map(\.coordinate.longitude).reduce(0, +) / Double(group.count)

                // Sort by encounter count (most encounters first)
                let sorted = group.sorted { ($0.cat?.encounters.count ?? 0) > ($1.cat?.encounters.count ?? 0) }
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

                // Hide overflow annotations and show a "+N" bubble at center
                for ann in overflow {
                    ann.originalCoordinate = ann.coordinate
                    ann.isSpread = true
                    hiddenAnnotations.insert(ObjectIdentifier(ann))
                }

                if !overflow.isEmpty {
                    let overflowPin = OverflowAnnotation()
                    overflowPin.coordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
                    overflowPin.overflowCats = overflow.compactMap(\.cat)
                    mapView.addAnnotation(overflowPin)
                }
            }

            // Re-add visible annotations (skip hidden overflow ones)
            for annotation in allAnnotations where !hiddenAnnotations.contains(ObjectIdentifier(annotation)) {
                mapView.addAnnotation(annotation)
            }

            // Disable clustering on spread annotations
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

            // Remove overflow bubbles
            let overflows = mapView.annotations.compactMap { $0 as? OverflowAnnotation }
            mapView.removeAnnotations(overflows)

            // Remove visible cat annotations
            let annotations = mapView.annotations.compactMap { $0 as? CatAnnotation }
            mapView.removeAnnotations(annotations)

            // Rebuild all annotations from allCats (includes ones that were hidden)
            var restored: [CatAnnotation] = []
            for cat in allCats {
                guard let lat = cat.location.latitude, let lng = cat.location.longitude else { continue }
                let a = CatAnnotation()
                a.cat = cat
                a.title = cat.displayName
                a.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
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
