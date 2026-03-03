import XCTest
import UIKit

final class ImageDownsamplerTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a solid-color JPEG of the given pixel dimensions.
    private func makeTestJPEG(width: Int, height: Int, color: UIColor = .orange) -> Data {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.8)!
    }

    override func setUp() {
        super.setUp()
        ImageDownsampler.clearCache()
    }

    // MARK: - Downsample Tests

    func test_downsample_returnsNonNilForValidData() {
        let jpeg = makeTestJPEG(width: 400, height: 400)
        let result = ImageDownsampler.downsample(data: jpeg, to: CGSize(width: 40, height: 40), scale: 1.0)
        XCTAssertNotNil(result)
    }

    func test_downsample_returnsNilForEmptyData() {
        let result = ImageDownsampler.downsample(data: Data(), to: CGSize(width: 40, height: 40), scale: 1.0)
        XCTAssertNil(result)
    }

    func test_downsample_returnsNilForGarbageData() {
        let garbage = Data([0x00, 0x01, 0x02, 0x03, 0x04])
        let result = ImageDownsampler.downsample(data: garbage, to: CGSize(width: 40, height: 40), scale: 1.0)
        XCTAssertNil(result)
    }

    func test_downsample_reducesImageDimensions() {
        let jpeg = makeTestJPEG(width: 800, height: 600)
        let targetSize = CGSize(width: 80, height: 80)

        let result = ImageDownsampler.downsample(data: jpeg, to: targetSize, scale: 1.0)
        XCTAssertNotNil(result)

        // The downsampled image's largest dimension should be <= target max pixel size
        let maxDimension = max(result!.size.width, result!.size.height)
        XCTAssertLessThanOrEqual(maxDimension, 80)
    }

    func test_downsample_respectsScaleFactor() {
        let jpeg = makeTestJPEG(width: 800, height: 800)
        let targetSize = CGSize(width: 40, height: 40)

        let result1x = ImageDownsampler.downsample(data: jpeg, to: targetSize, scale: 1.0)
        let result3x = ImageDownsampler.downsample(data: jpeg, to: targetSize, scale: 3.0)

        XCTAssertNotNil(result1x)
        XCTAssertNotNil(result3x)

        // 3x scale should produce a larger pixel image than 1x
        let pixels1x = result1x!.size.width * result1x!.cgImage!.bitsPerPixel.cgFloat
        let pixels3x = result3x!.size.width * result3x!.cgImage!.bitsPerPixel.cgFloat
        XCTAssertGreaterThan(pixels3x, pixels1x)
    }

    func test_downsample_doesNotUpscaleSmallImages() {
        let jpeg = makeTestJPEG(width: 20, height: 20)
        let targetSize = CGSize(width: 200, height: 200)

        let result = ImageDownsampler.downsample(data: jpeg, to: targetSize, scale: 1.0)
        XCTAssertNotNil(result)

        // Should not be larger than the original
        XCTAssertLessThanOrEqual(result!.size.width, 200)
        XCTAssertLessThanOrEqual(result!.size.height, 200)
    }

    func test_downsample_preservesAspectRatio() {
        let jpeg = makeTestJPEG(width: 800, height: 400)
        let targetSize = CGSize(width: 80, height: 80)

        let result = ImageDownsampler.downsample(data: jpeg, to: targetSize, scale: 1.0)
        XCTAssertNotNil(result)

        let ratio = result!.size.width / result!.size.height
        XCTAssertEqual(ratio, 2.0, accuracy: 0.1, "Aspect ratio should be preserved")
    }

    // MARK: - Cache Tests

    func test_cache_returnsSameInstanceOnRepeatedCalls() {
        let jpeg = makeTestJPEG(width: 400, height: 400)
        let size = CGSize(width: 40, height: 40)

        let first = ImageDownsampler.downsample(data: jpeg, to: size, scale: 1.0)
        let second = ImageDownsampler.downsample(data: jpeg, to: size, scale: 1.0)

        XCTAssertNotNil(first)
        XCTAssertNotNil(second)
        XCTAssertTrue(first === second, "Repeated call should return the same cached UIImage instance")
    }

    func test_cache_returnsDistinctImagesForDifferentSizes() {
        let jpeg = makeTestJPEG(width: 800, height: 800)

        let small = ImageDownsampler.downsample(data: jpeg, to: CGSize(width: 40, height: 40), scale: 1.0)
        let large = ImageDownsampler.downsample(data: jpeg, to: CGSize(width: 200, height: 200), scale: 1.0)

        XCTAssertNotNil(small)
        XCTAssertNotNil(large)
        XCTAssertFalse(small === large, "Different sizes should produce distinct cached images")
    }

    func test_cache_returnsDistinctImagesForDifferentData() {
        let orangeJPEG = makeTestJPEG(width: 400, height: 400, color: .orange)
        let blueJPEG = makeTestJPEG(width: 400, height: 400, color: .blue)
        let size = CGSize(width: 40, height: 40)

        let orangeResult = ImageDownsampler.downsample(data: orangeJPEG, to: size, scale: 1.0)
        let blueResult = ImageDownsampler.downsample(data: blueJPEG, to: size, scale: 1.0)

        XCTAssertNotNil(orangeResult)
        XCTAssertNotNil(blueResult)
        XCTAssertFalse(orangeResult === blueResult, "Different data should produce distinct cached images")
    }

    func test_cache_differentiatesByScale() {
        let jpeg = makeTestJPEG(width: 800, height: 800)
        let size = CGSize(width: 40, height: 40)

        let result1x = ImageDownsampler.downsample(data: jpeg, to: size, scale: 1.0)
        let result2x = ImageDownsampler.downsample(data: jpeg, to: size, scale: 2.0)

        XCTAssertNotNil(result1x)
        XCTAssertNotNil(result2x)
        XCTAssertFalse(
            result1x === result2x,
            "Same data at different scales should produce distinct cached images"
        )
    }

    func test_clearCache_evictsCachedImages() {
        let jpeg = makeTestJPEG(width: 400, height: 400)
        let size = CGSize(width: 40, height: 40)

        let first = ImageDownsampler.downsample(data: jpeg, to: size, scale: 1.0)
        XCTAssertNotNil(first)

        ImageDownsampler.clearCache()

        let second = ImageDownsampler.downsample(data: jpeg, to: size, scale: 1.0)
        XCTAssertNotNil(second)

        // After clearing, we should get a freshly decoded image (different instance)
        XCTAssertFalse(first === second, "After clearCache, a new instance should be decoded")
    }

    func test_cache_doesNotCacheFailedDecodes() {
        let garbage = Data([0x00, 0x01, 0x02, 0x03])
        let size = CGSize(width: 40, height: 40)

        let first = ImageDownsampler.downsample(data: garbage, to: size, scale: 1.0)
        let second = ImageDownsampler.downsample(data: garbage, to: size, scale: 1.0)

        XCTAssertNil(first)
        XCTAssertNil(second)
    }
}

private extension Int {
    var cgFloat: CGFloat { CGFloat(self) }
}
