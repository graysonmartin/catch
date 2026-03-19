import XCTest

final class ImageResizerTests: XCTestCase {

    // MARK: - resize(UIImage)

    func testResizeLargeImageToPhotoMax() {
        let image = createTestImage(width: 4032, height: 3024)
        let resized = ImageResizer.resize(image, maxDimension: ImageResizer.photoMaxDimension)

        XCTAssertEqual(resized.size.width, 1200, accuracy: 1)
        XCTAssertEqual(resized.size.height, 900, accuracy: 1)
    }

    func testResizeLargeImageToAvatarMax() {
        let image = createTestImage(width: 2000, height: 2000)
        let resized = ImageResizer.resize(image, maxDimension: ImageResizer.avatarMaxDimension)

        XCTAssertEqual(resized.size.width, 400, accuracy: 1)
        XCTAssertEqual(resized.size.height, 400, accuracy: 1)
    }

    func testResizePreservesAspectRatio() {
        let image = createTestImage(width: 3000, height: 1500) // 2:1
        let resized = ImageResizer.resize(image, maxDimension: 1200)

        XCTAssertEqual(resized.size.width, 1200, accuracy: 1)
        XCTAssertEqual(resized.size.height, 600, accuracy: 1)
    }

    func testResizePortraitImage() {
        let image = createTestImage(width: 1500, height: 3000)
        let resized = ImageResizer.resize(image, maxDimension: 1200)

        XCTAssertEqual(resized.size.width, 600, accuracy: 1)
        XCTAssertEqual(resized.size.height, 1200, accuracy: 1)
    }

    func testResizeSmallImageReturnsOriginal() {
        let image = createTestImage(width: 800, height: 600)
        let resized = ImageResizer.resize(image, maxDimension: 1200)

        // Should return the same object — already within bounds
        XCTAssertTrue(resized === image)
    }

    func testResizeExactlyAtMaxReturnsOriginal() {
        let image = createTestImage(width: 1200, height: 900)
        let resized = ImageResizer.resize(image, maxDimension: 1200)

        XCTAssertTrue(resized === image)
    }

    // MARK: - Helpers

    private func createTestImage(width: Int, height: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
}
