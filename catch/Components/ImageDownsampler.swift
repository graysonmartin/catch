import UIKit
import ImageIO

enum ImageDownsampler {

    /// Decodes image data at the target display size using `CGImageSource`,
    /// avoiding a full-resolution bitmap allocation.
    /// - Parameters:
    ///   - data: Raw image data (JPEG, PNG, etc.)
    ///   - pointSize: Target display size in points
    ///   - scale: Screen scale factor (defaults to main screen)
    /// - Returns: A `UIImage` sized for the target display, or `nil` if decoding fails
    static func downsample(
        data: Data,
        to pointSize: CGSize,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        let maxPixelDimension = max(pointSize.width, pointSize.height) * scale

        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            sourceOptions as CFDictionary
        ) else {
            return nil
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelDimension
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            downsampleOptions as CFDictionary
        ) else {
            return nil
        }

        return UIImage(cgImage: thumbnail)
    }
}
