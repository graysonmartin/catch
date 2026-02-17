import SwiftUI
import SwiftData
import MapKit

// MARK: - SwiftUI wrapper

struct CatMapView: View {
    @Query(sort: \Cat.name) private var cats: [Cat]
    @State private var selectedCat: Cat?
    @State private var showProfile = false
    @State private var clusterSelection: ClusterSelection?
    private var catsWithLocation: [Cat] {
        cats.filter { $0.location.hasCoordinates }
    }

    var body: some View {
        NavigationStack {
            Group {
                if catsWithLocation.isEmpty {
                    ContentUnavailableView(
                        "No Locations Yet",
                        systemImage: "map",
                        description: Text("Cats with GPS coordinates will appear here.")
                    )
                } else {
                    ClusterMapView(
                        cats: catsWithLocation,
                        onSelectCat: { cat in
                            selectedCat = cat
                            showProfile = true
                        },
                        onSelectCluster: { cats in
                            clusterSelection = ClusterSelection(cats: cats)
                        }
                    )
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showProfile) {
                if let cat = selectedCat {
                    CatProfileView(cat: cat)
                }
            }
            .sheet(item: $clusterSelection) { selection in
                ClusterListSheet(cats: selection.cats) { cat in
                    clusterSelection = nil
                    selectedCat = cat
                    showProfile = true
                }
            }
        }
    }
}

struct ClusterSelection: Identifiable {
    let id = UUID()
    let cats: [Cat]
}

// MARK: - Cluster list sheet

struct ClusterListSheet: View {
    let cats: [Cat]
    let onSelect: (Cat) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(cats) { cat in
                Button {
                    onSelect(cat)
                } label: {
                    HStack(spacing: 12) {
                        if let photoData = cat.photos.first, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "cat.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(CatchTheme.primary)
                                .clipShape(Circle())
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(cat.name)
                                .font(.headline)
                                .foregroundStyle(CatchTheme.textPrimary)
                            if !cat.location.name.isEmpty {
                                Text(cat.location.name)
                                    .font(.caption)
                                    .foregroundStyle(CatchTheme.textSecondary)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(CatchTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("\(cats.count) Cats Here")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Snapshot for change detection

struct CatSnapshot: Equatable {
    let id: PersistentIdentifier
    let name: String
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
        self.firstPhotoPrefix = cat.photos.first.map { Data($0.prefix(64)) }
    }
}

// MARK: - Annotation models

class CatAnnotation: MKPointAnnotation {
    var cat: Cat?
    var originalCoordinate: CLLocationCoordinate2D?
    var isSpread = false
}

class OverflowAnnotation: MKPointAnnotation {
    var overflowCats: [Cat] = []
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
            let a = CatAnnotation()
            a.cat = cat
            a.title = cat.name
            a.coordinate = CLLocationCoordinate2D(latitude: cat.location.latitude!, longitude: cat.location.longitude!)
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
                let id = "cluster"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? CatClusterView)
                    ?? CatClusterView(annotation: cluster, reuseIdentifier: id)
                view.annotation = cluster
                return view
            }
            if let overflow = annotation as? OverflowAnnotation {
                let id = "overflow"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? OverflowAnnotationView)
                    ?? OverflowAnnotationView(annotation: overflow, reuseIdentifier: id)
                view.annotation = overflow
                return view
            }
            if let catAnnotation = annotation as? CatAnnotation {
                let id = "catPin"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? CatAnnotationView)
                    ?? CatAnnotationView(annotation: catAnnotation, reuseIdentifier: id)
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
                    span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
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
            let zoomedIn = span.latitudeDelta < 0.005

            if zoomedIn && !isSpiderfied {
                spiderfy(mapView)
            } else if !zoomedIn && isSpiderfied {
                unspiderfy(mapView)
            }
        }

        private let maxSpiderfyCount = 9

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
            let radius = mapView.region.span.latitudeDelta * 0.08
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
                a.title = cat.name
                a.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                restored.append(a)
            }

            mapView.addAnnotations(restored)

            DispatchQueue.main.async {
                for annotation in restored {
                    if let view = mapView.view(for: annotation) as? CatAnnotationView {
                        view.clusteringIdentifier = "catCluster"
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
                    if dLat < 0.001 && dLng < 0.001 {
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

// MARK: - Individual cat pin

class CatAnnotationView: MKAnnotationView {
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "catCluster"
        collisionMode = .circle
        displayPriority = .defaultHigh
        render()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clusteringIdentifier = "catCluster"
    }

    override var annotation: (any MKAnnotation)? {
        didSet { render() }
    }

    private func render() {
        guard let catAnnotation = annotation as? CatAnnotation, let cat = catAnnotation.cat else { return }

        let size: CGFloat = 40
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let primary = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)

        image = renderer.image { ctx in
            if let photoData = cat.photos.first, let photo = UIImage(data: photoData) {
                let path = UIBezierPath(ovalIn: CGRect(x: 1, y: 1, width: size - 2, height: size - 2))
                ctx.cgContext.saveGState()
                path.addClip()
                let aspect = photo.size.width / photo.size.height
                let drawRect: CGRect
                if aspect > 1 {
                    let h = size; let w = h * aspect
                    drawRect = CGRect(x: (size - w) / 2, y: 0, width: w, height: h)
                } else {
                    let w = size; let h = w / aspect
                    drawRect = CGRect(x: 0, y: (size - h) / 2, width: w, height: h)
                }
                photo.draw(in: drawRect)
                ctx.cgContext.restoreGState()
                primary.setStroke()
                UIBezierPath(ovalIn: CGRect(x: 1, y: 1, width: size - 2, height: size - 2)).stroke()
            } else {
                primary.setFill()
                UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()
                let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
                if let icon = UIImage(systemName: "cat.fill", withConfiguration: config)?
                    .withTintColor(.white, renderingMode: .alwaysOriginal) {
                    let o = CGPoint(x: (size - icon.size.width) / 2, y: (size - icon.size.height) / 2)
                    icon.draw(at: o)
                }
            }
        }
    }
}

// MARK: - Overflow "+N" bubble (shown at center when >9 cats spiderfied)

class OverflowAnnotationView: MKAnnotationView {
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        displayPriority = .required
        render()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var annotation: (any MKAnnotation)? {
        didSet { render() }
    }

    private func render() {
        guard let overflow = annotation as? OverflowAnnotation else { return }
        let count = overflow.overflowCats.count

        let size: CGFloat = 36
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let primary = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)

        image = renderer.image { _ in
            primary.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()

            let text = "+\(count)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 13),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: (size - textSize.width) / 2, y: (size - textSize.height) / 2), withAttributes: attrs)
        }
    }
}

// MARK: - Cluster bubble

class CatClusterView: MKAnnotationView {
    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        displayPriority = .defaultHigh
        render()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var annotation: (any MKAnnotation)? {
        didSet { render() }
    }

    private func render() {
        guard let cluster = annotation as? MKClusterAnnotation else { return }
        let count = cluster.memberAnnotations.count

        let size: CGFloat = 44
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let primary = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)

        image = renderer.image { _ in
            primary.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: size - 6, height: size - 6)).fill()

            let text = "\(count)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: primary
            ]
            let textSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: (size - textSize.width) / 2, y: (size - textSize.height) / 2), withAttributes: attrs)
        }
    }
}
