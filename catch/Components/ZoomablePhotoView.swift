import SwiftUI
import UIKit

/// A UIKit-backed zoomable image view using `UIScrollView` for smooth
/// pinch-to-zoom and double-tap-to-zoom behavior.
/// SwiftUI's `MagnificationGesture` lacks the inertia and rubber-banding
/// that `UIScrollView` provides natively.
///
/// Supports two modes:
/// - Local `Data` images (decoded synchronously)
/// - Remote URL images (loaded asynchronously via `RemoteImageCache`)
struct ZoomablePhotoView: UIViewRepresentable {

    private let imageSource: ImageSource
    private let onDismiss: () -> Void

    private static let doubleTapScale: CGFloat = 3.0

    // MARK: - Image Source

    enum ImageSource: Equatable {
        case data(Data)
        case url(String)
    }

    // MARK: - Initializers

    init(imageData: Data, onDismiss: @escaping () -> Void) {
        self.imageSource = .data(imageData)
        self.onDismiss = onDismiss
    }

    init(imageUrl: String, onDismiss: @escaping () -> Void) {
        self.imageSource = .url(imageUrl)
        self.onDismiss = onDismiss
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> LayoutAwareScrollView {
        let scrollView = LayoutAwareScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = PhotoViewerState.minZoomScale
        scrollView.maximumZoomScale = PhotoViewerState.maxZoomScale
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.decelerationRate = .fast
        scrollView.backgroundColor = .clear

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.tag = 100
        scrollView.addSubview(imageView)

        // Double-tap to zoom
        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)

        // Drag-to-dismiss
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.delegate = context.coordinator
        scrollView.addGestureRecognizer(pan)

        context.coordinator.scrollView = scrollView

        scrollView.onLayoutChanged = { [weak scrollView] in
            guard let scrollView,
                  let imageView = scrollView.viewWithTag(100) as? UIImageView,
                  let imageSize = imageView.image?.size else { return }
            updateZoomScale(for: scrollView, imageSize: imageSize)
            centerImage(in: scrollView)
        }

        applyImage(to: imageView, in: scrollView, coordinator: context.coordinator)

        return scrollView
    }

    func updateUIView(_ scrollView: LayoutAwareScrollView, context: Context) {
        guard let imageView = scrollView.viewWithTag(100) as? UIImageView else { return }

        if context.coordinator.currentSource != imageSource {
            scrollView.zoomScale = 1.0
            applyImage(to: imageView, in: scrollView, coordinator: context.coordinator)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    // MARK: - Image Loading

    private func applyImage(
        to imageView: UIImageView,
        in scrollView: UIScrollView,
        coordinator: Coordinator
    ) {
        coordinator.currentSource = imageSource

        switch imageSource {
        case .data(let data):
            loadLocalImage(data, into: imageView, scrollView: scrollView)
        case .url(let urlString):
            loadRemoteImage(urlString, into: imageView, scrollView: scrollView)
        }
    }

    private func loadLocalImage(_ data: Data, into imageView: UIImageView, scrollView: UIScrollView) {
        guard let uiImage = UIImage(data: data) else { return }
        setImage(uiImage, in: imageView, scrollView: scrollView)
    }

    private func loadRemoteImage(
        _ urlString: String,
        into imageView: UIImageView,
        scrollView: UIScrollView
    ) {
        // Check cache synchronously first
        if let cached = RemoteImageCache.shared.memoryImage(for: urlString) {
            setImage(cached, in: imageView, scrollView: scrollView)
            return
        }

        // Show placeholder state (empty) while loading
        imageView.image = nil
        scrollView.contentSize = .zero

        // Load asynchronously
        Task { @MainActor in
            guard let downloaded = await RemoteImageCache.shared.loadImage(
                for: urlString,
                cacheKey: urlString
            ) else { return }

            // Verify the source hasn't changed while loading
            guard imageView.superview === scrollView else { return }
            setImage(downloaded, in: imageView, scrollView: scrollView)
        }
    }

    private func setImage(_ uiImage: UIImage, in imageView: UIImageView, scrollView: UIScrollView) {
        imageView.image = uiImage
        imageView.frame = CGRect(origin: .zero, size: uiImage.size)
        scrollView.contentSize = uiImage.size
        updateZoomScale(for: scrollView, imageSize: uiImage.size)
        centerImage(in: scrollView)
    }

    private func updateZoomScale(for scrollView: UIScrollView, imageSize: CGSize) {
        let boundsSize = scrollView.bounds.size
        guard boundsSize.width > 0, boundsSize.height > 0,
              imageSize.width > 0, imageSize.height > 0 else { return }

        let widthScale = boundsSize.width / imageSize.width
        let heightScale = boundsSize.height / imageSize.height
        let fitScale = min(widthScale, heightScale)

        scrollView.minimumZoomScale = fitScale
        scrollView.zoomScale = fitScale
    }

    private func centerImage(in scrollView: UIScrollView) {
        guard let imageView = scrollView.viewWithTag(100) else { return }
        let boundsSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize

        let offsetX = max(0, (boundsSize.width - contentSize.width) / 2)
        let offsetY = max(0, (boundsSize.height - contentSize.height) / 2)

        imageView.frame.origin = CGPoint(x: offsetX, y: offsetY)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {

        weak var scrollView: UIScrollView?
        var currentSource: ImageSource?

        private let onDismiss: () -> Void
        private var panStartY: CGFloat = 0
        private let dismissThreshold: CGFloat = 100

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        // MARK: - UIScrollViewDelegate

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.viewWithTag(100)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView = scrollView.viewWithTag(100) else { return }
            let boundsSize = scrollView.bounds.size
            let contentSize = scrollView.contentSize

            let offsetX = max(0, (boundsSize.width - contentSize.width) / 2)
            let offsetY = max(0, (boundsSize.height - contentSize.height) / 2)

            imageView.frame.origin = CGPoint(x: offsetX, y: offsetY)
        }

        // MARK: - Double Tap

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView else { return }

            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                let location = gesture.location(in: scrollView.viewWithTag(100))
                let zoomRect = zoomRectForScale(
                    ZoomablePhotoView.doubleTapScale,
                    center: location,
                    in: scrollView
                )
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }

        private func zoomRectForScale(
            _ scale: CGFloat,
            center: CGPoint,
            in scrollView: UIScrollView
        ) -> CGRect {
            let width = scrollView.bounds.width / scale
            let height = scrollView.bounds.height / scale
            let x = center.x - width / 2
            let y = center.y - height / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }

        // MARK: - Drag to Dismiss

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scrollView,
                  scrollView.zoomScale <= scrollView.minimumZoomScale + 0.01 else { return }

            let translation = gesture.translation(in: scrollView)

            switch gesture.state {
            case .began:
                panStartY = 0
            case .changed:
                let progress = translation.y / scrollView.bounds.height
                let alpha = max(0.3, 1.0 - abs(progress))
                scrollView.superview?.backgroundColor = UIColor.black.withAlphaComponent(alpha)
                scrollView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            case .ended, .cancelled:
                if abs(translation.y) > dismissThreshold {
                    onDismiss()
                } else {
                    UIView.animate(withDuration: 0.25) {
                        scrollView.transform = .identity
                        scrollView.superview?.backgroundColor = .black
                    }
                }
            default:
                break
            }
        }

        // MARK: - UIGestureRecognizerDelegate

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            // Allow pan alongside scroll view's own gestures when not zoomed
            true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let scrollView else { return true }

            // Only begin drag-to-dismiss when not zoomed and dragging mostly vertically
            guard scrollView.zoomScale <= scrollView.minimumZoomScale + 0.01 else { return false }

            let velocity = pan.velocity(in: scrollView)
            return abs(velocity.y) > abs(velocity.x)
        }
    }
}

// MARK: - Layout-Aware Scroll View

/// UIScrollView subclass that notifies when bounds change,
/// so we can recalculate zoom scale once the view has real dimensions.
final class LayoutAwareScrollView: UIScrollView {

    var onLayoutChanged: (() -> Void)?
    private var lastBoundsSize: CGSize = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastBoundsSize,
              bounds.size.width > 0, bounds.size.height > 0 else { return }
        lastBoundsSize = bounds.size
        onLayoutChanged?()
    }
}

