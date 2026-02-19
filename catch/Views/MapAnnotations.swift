import MapKit

// MARK: - Annotation models

class CatAnnotation: MKPointAnnotation {
    var cat: Cat?
    var originalCoordinate: CLLocationCoordinate2D?
    var isSpread = false
}

class OverflowAnnotation: MKPointAnnotation {
    var overflowCats: [Cat] = []
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
