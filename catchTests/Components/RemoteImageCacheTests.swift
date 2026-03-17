import XCTest
import UIKit

final class RemoteImageCacheTests: XCTestCase {

    private var sut: RemoteImageCache!

    override func setUp() {
        super.setUp()
        sut = RemoteImageCache(countLimit: 50, totalCostLimit: 10 * 1024 * 1024)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Operations

    func test_image_returnsNilForUnknownKey() {
        XCTAssertNil(sut.image(for: "https://example.com/missing.jpg"))
    }

    func test_setImage_thenRetrieve_returnsSameImage() {
        let image = makeImage(width: 10, height: 10)
        let key = "https://example.com/avatar.jpg"

        sut.setImage(image, for: key)

        let result = sut.image(for: key)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, image)
    }

    func test_setImage_differentKeys_storedIndependently() {
        let image1 = makeImage(width: 10, height: 10)
        let image2 = makeImage(width: 20, height: 20)

        sut.setImage(image1, for: "key1")
        sut.setImage(image2, for: "key2")

        XCTAssertEqual(sut.image(for: "key1"), image1)
        XCTAssertEqual(sut.image(for: "key2"), image2)
    }

    func test_setImage_sameKey_overwritesPrevious() {
        let original = makeImage(width: 10, height: 10)
        let replacement = makeImage(width: 20, height: 20)

        sut.setImage(original, for: "key")
        sut.setImage(replacement, for: "key")

        XCTAssertEqual(sut.image(for: "key"), replacement)
    }

    // MARK: - removeAll

    func test_removeAll_clearsAllEntries() {
        sut.setImage(makeImage(width: 10, height: 10), for: "key1")
        sut.setImage(makeImage(width: 10, height: 10), for: "key2")

        sut.removeAll()

        XCTAssertNil(sut.image(for: "key1"))
        XCTAssertNil(sut.image(for: "key2"))
    }

    func test_removeAll_allowsSubsequentInsertions() {
        sut.setImage(makeImage(width: 10, height: 10), for: "key")
        sut.removeAll()

        let newImage = makeImage(width: 20, height: 20)
        sut.setImage(newImage, for: "key")

        XCTAssertEqual(sut.image(for: "key"), newImage)
    }

    // MARK: - Protocol Conformance

    func test_conformsToImageCacheService() {
        let service: any ImageCacheService = sut
        XCTAssertNotNil(service)
    }

    // MARK: - Helpers

    private func makeImage(width: Int, height: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
}
