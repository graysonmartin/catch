import UIKit
import CommonCrypto
import ImageIO

// MARK: - ImageDownsamplingService Protocol

protocol ImageDownsamplingService {
    func downsample(data: Data, to pointSize: CGSize, scale: CGFloat) -> UIImage?
}

// MARK: - ImageDownsampler

final class ImageDownsampler: ImageDownsamplingService {

    static let shared = ImageDownsampler()

    private let cache = ImageCache()

    private init() {}

    /// Decodes image data at the target display size using `CGImageSource`,
    /// avoiding a full-resolution bitmap allocation. Results are cached
    /// in-memory so repeated renders of the same data at the same size
    /// return instantly without re-decoding.
    /// - Parameters:
    ///   - data: Raw image data (JPEG, PNG, etc.)
    ///   - pointSize: Target display size in points
    ///   - scale: Screen scale factor (defaults to main screen)
    /// - Returns: A `UIImage` sized for the target display, or `nil` if decoding fails
    func downsample(
        data: Data,
        to pointSize: CGSize,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        let maxPixelDimension = max(pointSize.width, pointSize.height) * scale
        let cacheKey = ImageCacheKey(dataHash: stableHash(for: data), maxPixelSize: Int(maxPixelDimension))

        if let cached = cache.image(for: cacheKey) {
            return cached
        }

        guard let image = decode(data: data, maxPixelDimension: maxPixelDimension) else {
            return nil
        }

        cache.store(image, for: cacheKey)
        return image
    }

    // internal for testability
    func clearCache() {
        cache.removeAll()
    }

    // MARK: - Decoding

    private func decode(data: Data, maxPixelDimension: CGFloat) -> UIImage? {
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

    // MARK: - Hashing

    /// Produces a stable 64-bit hash of image data using SHA-256 (truncated).
    /// SHA-256 is used instead of `Data.hashValue` because the latter is
    /// randomized per process and would break cross-render cache hits.
    private func stableHash(for data: Data) -> UInt64 {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &digest)
        }
        return digest.withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) }
    }
}

// MARK: - ImageCacheKey

/// Composite key combining the photo data's content hash with the
/// requested pixel size, so the same photo at different display sizes
/// is cached independently.
private struct ImageCacheKey: Hashable {
    let dataHash: UInt64
    let maxPixelSize: Int
}

// MARK: - NSCacheKey Wrapper

/// Wraps `ImageCacheKey` as an `NSObject` for use with `NSCache`.
private final class NSCacheKeyWrapper: NSObject {
    let key: ImageCacheKey

    init(_ key: ImageCacheKey) {
        self.key = key
    }

    override var hash: Int {
        key.hashValue
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSCacheKeyWrapper else { return false }
        return key == other.key
    }
}

// MARK: - ImageCache

/// Thread-safe, memory-pressure-aware image cache backed by `NSCache`.
/// `NSCache` is thread-safe for all operations, so `@unchecked Sendable` is valid.
private final class ImageCache: @unchecked Sendable {

    private static let defaultCostLimit = 75 * 1024 * 1024 // 75 MB

    private let storage = NSCache<NSCacheKeyWrapper, UIImage>()

    init(costLimit: Int = ImageCache.defaultCostLimit) {
        storage.totalCostLimit = costLimit
    }

    func image(for key: ImageCacheKey) -> UIImage? {
        storage.object(forKey: NSCacheKeyWrapper(key))
    }

    func store(_ image: UIImage, for key: ImageCacheKey) {
        let cost = estimatedCost(of: image)
        storage.setObject(image, forKey: NSCacheKeyWrapper(key), cost: cost)
    }

    func removeAll() {
        storage.removeAllObjects()
    }

    /// Estimates memory footprint as width * height * 4 bytes (RGBA).
    private func estimatedCost(of image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.width * cgImage.height * 4
    }
}
