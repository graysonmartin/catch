import UIKit

// MARK: - Protocol

protocol ImageCacheService: Sendable {
    func image(for key: String) -> UIImage?
    func setImage(_ image: UIImage, for key: String)
    func removeImage(for key: String)
    func removeAll()
}

// MARK: - Implementation

final class RemoteImageCache: ImageCacheService, @unchecked Sendable {
    static let shared = RemoteImageCache()

    private let cache = NSCache<NSString, UIImage>()

    /// Tracks in-flight downloads so concurrent requests for the same URL share one fetch.
    private var inFlightRequests: [String: Task<UIImage?, Never>] = [:]
    private let lock = NSLock()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 75 * 1024 * 1024 // 75 MB
    }

    /// Visible initializer for testing only.
    #if DEBUG
    init(countLimit: Int, totalCostLimit: Int) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }
    #endif

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

    func removeAll() {
        cache.removeAllObjects()
    }

    /// Returns a cached image or downloads it, deduplicating concurrent requests for the same URL.
    func loadImage(for urlString: String) async -> UIImage? {
        if let cached = image(for: urlString) { return cached }

        let existingTask: Task<UIImage?, Never>? = lock.withLock {
            inFlightRequests[urlString]
        }
        if let task = existingTask {
            return await task.value
        }

        let task = Task<UIImage?, Never> {
            guard let url = URL(string: urlString),
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let downloaded = UIImage(data: data) else {
                lock.withLock { inFlightRequests[urlString] = nil }
                return nil
            }
            setImage(downloaded, for: urlString)
            lock.withLock { inFlightRequests[urlString] = nil }
            return downloaded
        }

        lock.withLock { inFlightRequests[urlString] = task }
        return await task.value
    }

    /// Prefetches images for the given URLs concurrently, caching each result.
    /// Skips URLs already in the cache.
    func prefetch(urls: [String]) async {
        let uncached = urls.filter { image(for: $0) == nil }
        guard !uncached.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for urlString in uncached {
                group.addTask {
                    guard let url = URL(string: urlString),
                          let (data, _) = try? await URLSession.shared.data(from: url),
                          let downloaded = UIImage(data: data) else { return }
                    self.setImage(downloaded, for: urlString)
                }
            }
        }
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
