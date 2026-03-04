import Foundation

/// Manages page index and zoom state for the full-screen photo viewer.
/// Extracted as a standalone type for testability.
final class PhotoViewerState: ObservableObject {

    let photos: [Data]

    @Published private(set) var currentIndex: Int
    @Published private(set) var zoomScale: CGFloat = 1.0

    // MARK: - Zoom Bounds

    static let minZoomScale: CGFloat = 1.0
    static let maxZoomScale: CGFloat = 5.0

    // MARK: - Init

    init(photos: [Data], initialIndex: Int = 0) {
        self.photos = photos
        self.currentIndex = Self.clampedIndex(initialIndex, count: photos.count)
    }

    // MARK: - Page Navigation

    var pageCount: Int { photos.count }

    var canGoForward: Bool { currentIndex < photos.count - 1 }
    var canGoBack: Bool { currentIndex > 0 }

    func goToPage(_ index: Int) {
        let clamped = Self.clampedIndex(index, count: photos.count)
        guard clamped != currentIndex else { return }
        currentIndex = clamped
        resetZoom()
    }

    // MARK: - Zoom

    func setZoomScale(_ scale: CGFloat) {
        zoomScale = Self.clampedZoom(scale)
    }

    func resetZoom() {
        zoomScale = Self.minZoomScale
    }

    var isZoomed: Bool { zoomScale > Self.minZoomScale + 0.01 }

    // MARK: - Helpers

    private static func clampedIndex(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return max(0, min(index, count - 1))
    }

    static func clampedZoom(_ scale: CGFloat) -> CGFloat {
        max(minZoomScale, min(scale, maxZoomScale))
    }
}
