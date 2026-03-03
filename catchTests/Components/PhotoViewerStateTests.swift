import XCTest

@MainActor
final class PhotoViewerStateTests: XCTestCase {

    // MARK: - Helpers

    private func makeSamplePhotos(count: Int) -> [Data] {
        (0..<count).map { _ in Data([0xFF, 0xD8, 0xFF, 0xE0]) }
    }

    // MARK: - Initialization

    func test_init_setsCurrentIndexToInitialIndex() {
        let photos = makeSamplePhotos(count: 5)
        let state = PhotoViewerState(photos: photos, initialIndex: 2)
        XCTAssertEqual(state.currentIndex, 2)
    }

    func test_init_clampsNegativeInitialIndex() {
        let photos = makeSamplePhotos(count: 3)
        let state = PhotoViewerState(photos: photos, initialIndex: -1)
        XCTAssertEqual(state.currentIndex, 0)
    }

    func test_init_clampsOverflowInitialIndex() {
        let photos = makeSamplePhotos(count: 3)
        let state = PhotoViewerState(photos: photos, initialIndex: 10)
        XCTAssertEqual(state.currentIndex, 2)
    }

    func test_init_handlesEmptyPhotos() {
        let state = PhotoViewerState(photos: [], initialIndex: 0)
        XCTAssertEqual(state.currentIndex, 0)
        XCTAssertEqual(state.pageCount, 0)
    }

    func test_init_defaultZoomIsOne() {
        let photos = makeSamplePhotos(count: 1)
        let state = PhotoViewerState(photos: photos)
        XCTAssertEqual(state.zoomScale, 1.0)
    }

    // MARK: - Page Navigation

    func test_pageCount_returnsPhotoCount() {
        let photos = makeSamplePhotos(count: 4)
        let state = PhotoViewerState(photos: photos)
        XCTAssertEqual(state.pageCount, 4)
    }

    func test_canGoForward_trueWhenNotOnLastPage() {
        let photos = makeSamplePhotos(count: 3)
        let state = PhotoViewerState(photos: photos, initialIndex: 0)
        XCTAssertTrue(state.canGoForward)
    }

    func test_canGoForward_falseOnLastPage() {
        let photos = makeSamplePhotos(count: 3)
        let state = PhotoViewerState(photos: photos, initialIndex: 2)
        XCTAssertFalse(state.canGoForward)
    }

    func test_canGoBack_trueWhenNotOnFirstPage() {
        let photos = makeSamplePhotos(count: 3)
        let state = PhotoViewerState(photos: photos, initialIndex: 1)
        XCTAssertTrue(state.canGoBack)
    }

    func test_canGoBack_falseOnFirstPage() {
        let photos = makeSamplePhotos(count: 3)
        let state = PhotoViewerState(photos: photos, initialIndex: 0)
        XCTAssertFalse(state.canGoBack)
    }

    func test_goToPage_updatesCurrentIndex() {
        let photos = makeSamplePhotos(count: 5)
        let state = PhotoViewerState(photos: photos, initialIndex: 0)
        state.goToPage(3)
        XCTAssertEqual(state.currentIndex, 3)
    }

    func test_goToPage_clampsToValidRange() {
        let photos = makeSamplePhotos(count: 3)
        let state = PhotoViewerState(photos: photos, initialIndex: 0)
        state.goToPage(10)
        XCTAssertEqual(state.currentIndex, 2)
    }

    func test_goToPage_clampsNegativeIndex() {
        let photos = makeSamplePhotos(count: 3)
        let state = PhotoViewerState(photos: photos, initialIndex: 1)
        state.goToPage(-5)
        XCTAssertEqual(state.currentIndex, 0)
    }

    func test_goToPage_resetsZoom() {
        let photos = makeSamplePhotos(count: 3)
        let state = PhotoViewerState(photos: photos, initialIndex: 0)
        state.setZoomScale(3.0)
        XCTAssertEqual(state.zoomScale, 3.0)
        state.goToPage(1)
        XCTAssertEqual(state.zoomScale, 1.0)
    }

    func test_goToPage_doesNothingForSamePage() {
        let photos = makeSamplePhotos(count: 3)
        let state = PhotoViewerState(photos: photos, initialIndex: 1)
        state.setZoomScale(2.5)
        state.goToPage(1)
        // Zoom should remain unchanged since page didn't change
        XCTAssertEqual(state.zoomScale, 2.5)
    }

    // MARK: - Zoom

    func test_setZoomScale_clampsToMinimum() {
        let photos = makeSamplePhotos(count: 1)
        let state = PhotoViewerState(photos: photos)
        state.setZoomScale(0.1)
        XCTAssertEqual(state.zoomScale, PhotoViewerState.minZoomScale)
    }

    func test_setZoomScale_clampsToMaximum() {
        let photos = makeSamplePhotos(count: 1)
        let state = PhotoViewerState(photos: photos)
        state.setZoomScale(100.0)
        XCTAssertEqual(state.zoomScale, PhotoViewerState.maxZoomScale)
    }

    func test_setZoomScale_acceptsValidScale() {
        let photos = makeSamplePhotos(count: 1)
        let state = PhotoViewerState(photos: photos)
        state.setZoomScale(2.5)
        XCTAssertEqual(state.zoomScale, 2.5)
    }

    func test_resetZoom_setsScaleToMinimum() {
        let photos = makeSamplePhotos(count: 1)
        let state = PhotoViewerState(photos: photos)
        state.setZoomScale(4.0)
        state.resetZoom()
        XCTAssertEqual(state.zoomScale, PhotoViewerState.minZoomScale)
    }

    func test_isZoomed_falseAtDefaultScale() {
        let photos = makeSamplePhotos(count: 1)
        let state = PhotoViewerState(photos: photos)
        XCTAssertFalse(state.isZoomed)
    }

    func test_isZoomed_trueWhenScaleAboveMinimum() {
        let photos = makeSamplePhotos(count: 1)
        let state = PhotoViewerState(photos: photos)
        state.setZoomScale(2.0)
        XCTAssertTrue(state.isZoomed)
    }

    // MARK: - Static Helpers

    func test_clampedZoom_clampsCorrectly() {
        XCTAssertEqual(PhotoViewerState.clampedZoom(0.5), PhotoViewerState.minZoomScale)
        XCTAssertEqual(PhotoViewerState.clampedZoom(10.0), PhotoViewerState.maxZoomScale)
        XCTAssertEqual(PhotoViewerState.clampedZoom(3.0), 3.0)
    }
}
