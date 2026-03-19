import XCTest
@testable import CatchCore

final class ThumbnailURLTests: XCTestCase {

    // MARK: - thumbnailURL

    func testJpgExtension() {
        let result = ThumbnailURL.thumbnailURL(for: "https://example.com/photos/abc123.jpg")
        XCTAssertEqual(result, "https://example.com/photos/abc123_thumb.jpg")
    }

    func testJpegExtension() {
        let result = ThumbnailURL.thumbnailURL(for: "https://example.com/photos/abc123.jpeg")
        XCTAssertEqual(result, "https://example.com/photos/abc123_thumb.jpeg")
    }

    func testPngExtension() {
        let result = ThumbnailURL.thumbnailURL(for: "https://example.com/photos/abc123.png")
        XCTAssertEqual(result, "https://example.com/photos/abc123_thumb.png")
    }

    func testURLWithQueryParams() {
        let result = ThumbnailURL.thumbnailURL(for: "https://example.com/photos/abc.jpg?token=xyz")
        XCTAssertEqual(result, "https://example.com/photos/abc_thumb.jpg?token=xyz")
    }

    func testURLWithFragment() {
        let result = ThumbnailURL.thumbnailURL(for: "https://example.com/photos/abc.jpg#section")
        XCTAssertEqual(result, "https://example.com/photos/abc_thumb.jpg#section")
    }

    func testURLWithDeepPath() {
        let url = "https://project.supabase.co/storage/v1/object/public/cat-photos/user-id/abc_0.jpg"
        let result = ThumbnailURL.thumbnailURL(for: url)
        XCTAssertEqual(result, "https://project.supabase.co/storage/v1/object/public/cat-photos/user-id/abc_0_thumb.jpg")
    }

    func testURLWithNoExtension() {
        let result = ThumbnailURL.thumbnailURL(for: "https://example.com/photos/abc123")
        XCTAssertNil(result)
    }

    // MARK: - thumbnailOrOriginal

    func testThumbnailOrOriginalWithValidURL() {
        let url = "https://example.com/photo.jpg"
        let result = ThumbnailURL.thumbnailOrOriginal(for: url)
        XCTAssertEqual(result, "https://example.com/photo_thumb.jpg")
    }

    func testThumbnailOrOriginalFallsBackForNoExtension() {
        let url = "https://example.com/photo"
        let result = ThumbnailURL.thumbnailOrOriginal(for: url)
        XCTAssertEqual(result, url, "Should return original URL when no extension found")
    }
}
