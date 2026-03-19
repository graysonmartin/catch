import MapKit
import CatchCore

enum AnnotationLayout {
    static let catPinSize: CGFloat = 40
    static let catPinBorderInset: CGFloat = 1
    static let catIconPointSize: CGFloat = 18
    static let overflowBubbleSize: CGFloat = 36
    static let overflowFontSize: CGFloat = 13
    static let clusterBubbleSize: CGFloat = 44
    static let clusterBorderInset: CGFloat = 3
    static let clusterFontSize: CGFloat = 16
    static let clusteringID = "catCluster"
}

// MARK: - Unified pin model

enum MapPin {
    case local(Cat)
    case remote(encounter: CloudEncounter, cat: CloudCat?, owner: CloudUserProfile)

    var photoUrl: String? {
        switch self {
        case .local(let cat): return cat.photoUrls.first
        case .remote(_, let cat, _): return cat?.photoUrls.first
        }
    }

    var displayName: String {
        switch self {
        case .local(let cat): return cat.displayName
        case .remote(_, let cat, _): return cat?.displayName ?? CatchStrings.Common.unnamedCatFallback
        }
    }

    var isRemote: Bool {
        if case .remote = self { return true }
        return false
    }

    /// Used for spiderfy sort order — local cats with more encounters surface first
    var encounterSortWeight: Int {
        if case .local(let cat) = self { return cat.encounters.count }
        return 0
    }

    var coordinate: CLLocationCoordinate2D? {
        switch self {
        case .local(let cat):
            guard let lat = cat.location.latitude, let lng = cat.location.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        case .remote(let encounter, _, _):
            guard let lat = encounter.locationLatitude, let lng = encounter.locationLongitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
    }
}

// MARK: - Annotation models

class CatAnnotation: MKPointAnnotation {
    var pin: MapPin?
    var originalCoordinate: CLLocationCoordinate2D?
    var isSpread = false
}

class OverflowAnnotation: MKPointAnnotation {
    var overflowPins: [MapPin] = []
}

// MARK: - Individual cat pin

class CatAnnotationView: MKAnnotationView {
    private var imageLoadTask: Task<Void, Never>?

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = AnnotationLayout.clusteringID
        collisionMode = .circle
        displayPriority = .defaultHigh
        render()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        clusteringIdentifier = AnnotationLayout.clusteringID
        imageLoadTask?.cancel()
        imageLoadTask = nil
    }

    override var annotation: (any MKAnnotation)? {
        didSet { render() }
    }

    private func render() {
        imageLoadTask?.cancel()
        guard let catAnnotation = annotation as? CatAnnotation, let pin = catAnnotation.pin else { return }

        let borderColor = pin.isRemote ? CatchTheme.remotePinUIColor : CatchTheme.primaryUIColor

        // Check cache first — instant, no flicker
        if let url = pin.photoUrl, let cached = RemoteImageCache.shared.memoryImage(for: url) {
            renderPhoto(cached, borderColor: borderColor)
            return
        }

        // Show placeholder while loading
        renderPlaceholder(borderColor: borderColor)

        // Load photo async
        guard let url = pin.photoUrl else { return }
        imageLoadTask = Task { [weak self] in
            guard let loaded = await RemoteImageCache.shared.loadImage(for: url) else { return }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.renderPhoto(loaded, borderColor: borderColor)
            }
        }
    }

    private func renderPlaceholder(borderColor: UIColor) {
        let size = AnnotationLayout.catPinSize
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        image = renderer.image { _ in
            borderColor.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()
            let config = UIImage.SymbolConfiguration(pointSize: AnnotationLayout.catIconPointSize, weight: .medium)
            if let icon = UIImage(systemName: "cat.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let o = CGPoint(x: (size - icon.size.width) / 2, y: (size - icon.size.height) / 2)
                icon.draw(at: o)
            }
        }
    }

    private func renderPhoto(_ photo: UIImage, borderColor: UIColor) {
        let size = AnnotationLayout.catPinSize
        let borderWidth: CGFloat = AnnotationLayout.catPinBorderInset + 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        image = renderer.image { ctx in
            // Outer border circle
            borderColor.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()

            // Clip to inner circle and draw photo
            let innerRect = CGRect(x: borderWidth, y: borderWidth,
                                   width: size - borderWidth * 2, height: size - borderWidth * 2)
            ctx.cgContext.saveGState()
            UIBezierPath(ovalIn: innerRect).addClip()

            let photoSize = photo.size
            let scale = max(innerRect.width / photoSize.width, innerRect.height / photoSize.height)
            let drawRect = CGRect(
                x: innerRect.midX - (photoSize.width * scale) / 2,
                y: innerRect.midY - (photoSize.height * scale) / 2,
                width: photoSize.width * scale,
                height: photoSize.height * scale
            )
            photo.draw(in: drawRect)
            ctx.cgContext.restoreGState()
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
        let count = overflow.overflowPins.count

        let size = AnnotationLayout.overflowBubbleSize
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        image = renderer.image { _ in
            CatchTheme.primaryUIColor.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()

            let text = "+\(count)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: AnnotationLayout.overflowFontSize),
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

        let size = AnnotationLayout.clusterBubbleSize
        let inset = AnnotationLayout.clusterBorderInset
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        image = renderer.image { _ in
            CatchTheme.primaryUIColor.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)).fill()

            let text = "\(count)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: AnnotationLayout.clusterFontSize),
                .foregroundColor: CatchTheme.primaryUIColor
            ]
            let textSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: (size - textSize.width) / 2, y: (size - textSize.height) / 2), withAttributes: attrs)
        }
    }
}
