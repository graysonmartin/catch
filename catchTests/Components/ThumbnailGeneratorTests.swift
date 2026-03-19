import XCTest
@testable import CatchCore

final class ThumbnailGeneratorTests: XCTestCase {

    func testGenerateThumbnailFromValidJPEG() throws {
        let sourceImage = createTestImage(width: 1200, height: 800)
        let sourceData = try XCTUnwrap(sourceImage.jpegData(compressionQuality: 0.8))

        let thumbData = try XCTUnwrap(ThumbnailGenerator.generateThumbnail(from: sourceData, maxDimension: 300))

        // Thumbnail should be smaller than source
        XCTAssertLessThan(thumbData.count, sourceData.count)

        // Thumbnail should be valid image data
        let thumbImage = try XCTUnwrap(UIImage(data: thumbData))

        // Longest edge should be <= 300
        let longestEdge = max(thumbImage.size.width, thumbImage.size.height)
        XCTAssertLessThanOrEqual(longestEdge, 300)
    }

    func testGenerateThumbnailPreservesAspectRatio() throws {
        let sourceImage = createTestImage(width: 1200, height: 600) // 2:1 ratio
        let sourceData = try XCTUnwrap(sourceImage.jpegData(compressionQuality: 0.8))

        let thumbData = try XCTUnwrap(ThumbnailGenerator.generateThumbnail(from: sourceData, maxDimension: 300))
        let thumbImage = try XCTUnwrap(UIImage(data: thumbData))

        // Width should be 300 (longest edge), height should be ~150
        XCTAssertEqual(thumbImage.size.width, 300, accuracy: 1)
        XCTAssertEqual(thumbImage.size.height, 150, accuracy: 1)
    }

    func testGenerateThumbnailWithSmallImage() throws {
        let sourceImage = createTestImage(width: 100, height: 80)
        let sourceData = try XCTUnwrap(sourceImage.jpegData(compressionQuality: 0.8))

        let thumbData = ThumbnailGenerator.generateThumbnail(from: sourceData, maxDimension: 300)
        XCTAssertNotNil(thumbData, "Should still produce valid output for small images")
    }

    func testGenerateThumbnailWithInvalidData() {
        let invalidData = Data("not an image".utf8)
        let result = ThumbnailGenerator.generateThumbnail(from: invalidData)
        XCTAssertNil(result)
    }

    func testGenerateThumbnailWithEmptyData() {
        let result = ThumbnailGenerator.generateThumbnail(from: Data())
        XCTAssertNil(result)
    }

    // MARK: - Helpers

    private func createTestImage(width: Int, height: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
}
