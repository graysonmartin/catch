import SwiftUI
import UIKit

/// A UIKit-backed zoomable image view using `UIScrollView` for smooth
/// pinch-to-zoom and double-tap-to-zoom behavior.
/// SwiftUI's `MagnificationGesture` lacks the inertia and rubber-banding
/// that `UIScrollView` provides natively.
struct ZoomablePhotoView: UIViewRepresentable {

    let imageData: Data
    let onDismiss: () -> Void

    private static let doubleTapScale: CGFloat = 3.0

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
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
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)

        // Drag-to-dismiss
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        scrollView.addGestureRecognizer(pan)

        context.coordinator.scrollView = scrollView

        loadImage(into: imageView, scrollView: scrollView)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = scrollView.viewWithTag(100) as? UIImageView else { return }

        // Only reload if the data actually changed
        if context.coordinator.currentData != imageData {
            scrollView.zoomScale = 1.0
            loadImage(into: imageView, scrollView: scrollView)
            context.coordinator.currentData = imageData
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    // MARK: - Image Loading

    private func loadImage(into imageView: UIImageView, scrollView: UIScrollView) {
        guard let uiImage = UIImage(data: imageData) else { return }
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
        var currentData: Data?

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
                let zoomRect = zoomRectForScale(ZoomablePhotoView.doubleTapScale, center: location, in: scrollView)
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }

        private func zoomRectForScale(_ scale: CGFloat, center: CGPoint, in scrollView: UIScrollView) -> CGRect {
            let width = scrollView.bounds.width / scale
            let height = scrollView.bounds.height / scale
            let x = center.x - width / 2
            let y = center.y - height / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }

        // MARK: - Drag to Dismiss

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scrollView, scrollView.zoomScale <= scrollView.minimumZoomScale + 0.01 else { return }

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
