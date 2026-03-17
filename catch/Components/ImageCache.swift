import UIKit

final class RemoteImageCache: @unchecked Sendable {
    static let shared = RemoteImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 75 * 1024 * 1024 // 75 MB
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func removeImage(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    /// Returns JPEG data for the given URL, checking the in-memory cache first
    /// and falling back to a network fetch. Caches the image on a cache miss.
    func jpegData(for urlString: String, compressionQuality: CGFloat) async -> Data? {
        if let cached = image(for: urlString) {
            return cached.jpegData(compressionQuality: compressionQuality)
        }
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let downloaded = UIImage(data: data) else {
            return nil
        }
        setImage(downloaded, for: urlString)
        return downloaded.jpegData(compressionQuality: compressionQuality)
    }
}
