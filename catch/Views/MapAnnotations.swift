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

    var photoData: Data? {
        switch self {
        case .local(let cat): return cat.photos.first
        case .remote(_, let cat, _): return cat?.photos.first
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
    }

    override var annotation: (any MKAnnotation)? {
        didSet { render() }
    }

    private func render() {
        guard let catAnnotation = annotation as? CatAnnotation, let pin = catAnnotation.pin else { return }

        let size = AnnotationLayout.catPinSize
        let inset = AnnotationLayout.catPinBorderInset
        let borderColor = pin.isRemote ? CatchTheme.remotePinUIColor : CatchTheme.primaryUIColor
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        image = renderer.image { ctx in
            if let photoData = pin.photoData,
               let photo = ImageDownsampler.shared.downsample(data: photoData, to: CGSize(width: size, height: size)) {
                let path = UIBezierPath(ovalIn: CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2))
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
                borderColor.setStroke()
                UIBezierPath(ovalIn: CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)).stroke()
            } else {
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
