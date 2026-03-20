import XCTest
import ImageIO

final class EXIFStripperTests: XCTestCase {

    // MARK: - Metadata Stripping

    func testStripMetadataRemovesPIIFromJPEG() throws {
        let sourceData = try createJPEGWithMetadata()

        // Verify source has PII metadata
        let sourceMeta = try extractMetadata(from: sourceData)
        let sourceExif = sourceMeta[kCGImagePropertyExifDictionary as String] as? [String: Any]
        let sourceGPS = sourceMeta[kCGImagePropertyGPSDictionary as String] as? [String: Any]
        let sourceTIFF = sourceMeta[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        XCTAssertNotNil(sourceExif?[kCGImagePropertyExifDateTimeOriginal as String])
        XCTAssertNotNil(sourceExif?[kCGImagePropertyExifUserComment as String])
        XCTAssertNotNil(sourceGPS?[kCGImagePropertyGPSLatitude as String])
        XCTAssertNotNil(sourceTIFF?[kCGImagePropertyTIFFMake as String])

        let stripped = EXIFStripper.stripMetadata(from: sourceData)
        let strippedMeta = try extractMetadata(from: stripped)

        // GPS dictionary must be completely gone
        XCTAssertNil(
            strippedMeta[kCGImagePropertyGPSDictionary as String],
            "GPS dictionary should be removed"
        )

        // IPTC dictionary must be gone
        XCTAssertNil(
            strippedMeta[kCGImagePropertyIPTCDictionary as String],
            "IPTC dictionary should be removed"
        )

        // EXIF PII fields must be gone (the encoder may add a minimal EXIF dict
        // with color space info — that's fine, but PII fields must not survive)
        let strippedExif = strippedMeta[kCGImagePropertyExifDictionary as String] as? [String: Any]
        XCTAssertNil(
            strippedExif?[kCGImagePropertyExifDateTimeOriginal as String],
            "EXIF DateTimeOriginal should be removed"
        )
        XCTAssertNil(
            strippedExif?[kCGImagePropertyExifLensMake as String],
            "EXIF LensMake should be removed"
        )
        XCTAssertNil(
            strippedExif?[kCGImagePropertyExifUserComment as String],
            "EXIF UserComment should be removed"
        )

        // TIFF device fields must be gone
        let strippedTIFF = strippedMeta[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        XCTAssertNil(
            strippedTIFF?[kCGImagePropertyTIFFMake as String],
            "TIFF Make (device manufacturer) should be removed"
        )
        XCTAssertNil(
            strippedTIFF?[kCGImagePropertyTIFFModel as String],
            "TIFF Model (device model) should be removed"
        )
    }

    func testStrippedDataIsValidJPEG() throws {
        let sourceData = try createJPEGWithMetadata()
        let stripped = EXIFStripper.stripMetadata(from: sourceData)

        // Should still be valid image data
        let image = UIImage(data: stripped)
        XCTAssertNotNil(image, "Stripped data should produce a valid UIImage")

        // Verify dimensions are preserved
        let sourceImage = try XCTUnwrap(UIImage(data: sourceData))
        let strippedImage = try XCTUnwrap(image)
        XCTAssertEqual(sourceImage.size.width, strippedImage.size.width, accuracy: 1)
        XCTAssertEqual(sourceImage.size.height, strippedImage.size.height, accuracy: 1)
    }

    func testStripMetadataRemovesGPSCoordinates() throws {
        let sourceData = try createJPEGWithMetadata()

        // Verify GPS is present in source
        let sourceMeta = try extractMetadata(from: sourceData)
        let sourceGPS = sourceMeta[kCGImagePropertyGPSDictionary as String] as? [String: Any]
        XCTAssertNotNil(sourceGPS?[kCGImagePropertyGPSLatitude as String])

        let stripped = EXIFStripper.stripMetadata(from: sourceData)
        let strippedMeta = try extractMetadata(from: stripped)

        XCTAssertNil(
            strippedMeta[kCGImagePropertyGPSDictionary as String],
            "GPS dictionary should be completely removed"
        )
    }

    // MARK: - Edge Cases

    func testStripMetadataWithEmptyDataReturnsEmpty() {
        let result = EXIFStripper.stripMetadata(from: Data())
        XCTAssertTrue(result.isEmpty)
    }

    func testStripMetadataWithInvalidDataReturnsOriginal() {
        let invalidData = Data("not an image".utf8)
        let result = EXIFStripper.stripMetadata(from: invalidData)
        XCTAssertEqual(result, invalidData, "Invalid data should be returned unchanged")
    }

    func testStripMetadataWithCleanJPEGStillProducesValidOutput() throws {
        // JPEG without explicit metadata should still work
        let image = createTestImage(width: 200, height: 150)
        let cleanData = try XCTUnwrap(image.jpegData(compressionQuality: 0.8))

        let result = EXIFStripper.stripMetadata(from: cleanData)

        let resultImage = UIImage(data: result)
        XCTAssertNotNil(resultImage, "Clean JPEG should remain valid after stripping")
    }

    // MARK: - Helpers

    /// Creates JPEG data with embedded EXIF, GPS, and TIFF metadata.
    private func createJPEGWithMetadata() throws -> Data {
        let image = createTestImage(width: 400, height: 300)
        let jpegData = try XCTUnwrap(image.jpegData(compressionQuality: 0.8))

        guard let source = CGImageSourceCreateWithData(jpegData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            XCTFail("Failed to create image source")
            return Data()
        }

        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            XCTFail("Failed to create image destination")
            return Data()
        }

        let metadata: [String: Any] = [
            kCGImagePropertyExifDictionary as String: [
                kCGImagePropertyExifDateTimeOriginal as String: "2025:06:15 14:30:00",
                kCGImagePropertyExifLensMake as String: "Apple",
                kCGImagePropertyExifUserComment as String: "Test photo"
            ],
            kCGImagePropertyGPSDictionary as String: [
                kCGImagePropertyGPSLatitude as String: 37.7749,
                kCGImagePropertyGPSLatitudeRef as String: "N",
                kCGImagePropertyGPSLongitude as String: 122.4194,
                kCGImagePropertyGPSLongitudeRef as String: "W"
            ],
            kCGImagePropertyTIFFDictionary as String: [
                kCGImagePropertyTIFFMake as String: "Apple",
                kCGImagePropertyTIFFModel as String: "iPhone 15 Pro"
            ]
        ]

        CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            XCTFail("Failed to finalize image with metadata")
            return Data()
        }

        return mutableData as Data
    }

    private func extractMetadata(from data: Data) throws -> [String: Any] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            throw MetadataError.cannotRead
        }
        return properties
    }

    private func createTestImage(width: Int, height: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { ctx in
            UIColor.orange.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private enum MetadataError: Error {
        case cannotRead
    }
}
