import XCTest
import UIKit

final class ImageDownsamplerTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a solid-color JPEG of the given pixel dimensions.
    private func makeTestJPEG(width: Int, height: Int) -> Data {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.8)!
    }

    // MARK: - Tests

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
}

private extension Int {
    var cgFloat: CGFloat { CGFloat(self) }
}
