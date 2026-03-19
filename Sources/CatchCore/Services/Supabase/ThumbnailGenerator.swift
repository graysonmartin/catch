import CoreGraphics
import Foundation
import ImageIO

/// Generates thumbnail JPEG data from source image data using ImageIO.
/// Works without UIKit — uses CGImageSource for memory-efficient downsampling.
public enum ThumbnailGenerator {

    /// Default max dimension for thumbnails (pixels).
    public static let defaultMaxDimension: CGFloat = 300

    /// Default JPEG compression quality for thumbnails.
    private static let compressionQuality: CGFloat = 0.7

    /// Creates thumbnail JPEG data from source image data.
    /// Returns `nil` if the source data can't be decoded.
    public static func generateThumbnail(
        from data: Data,
        maxDimension: CGFloat = defaultMaxDimension
    ) -> Data? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            return nil
        }

        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else {
            return nil
        }

        // Encode as JPEG
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            return nil
        }

        let encodeOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        CGImageDestinationAddImage(destination, cgImage, encodeOptions as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}
