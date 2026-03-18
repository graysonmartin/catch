import CryptoKit
import UIKit

// MARK: - Protocol

protocol ImageCacheService: Sendable {
    func memoryImage(for key: String) -> UIImage?
    func setImage(_ image: UIImage, for key: String)
    func setImage(_ image: UIImage, data: Data, for key: String)
    func removeImage(for key: String)
    func removeAll()
}

// MARK: - Disk Cache

/// All mutable state is serialized on `ioQueue`.
private final class DiskImageCache: @unchecked Sendable {

    private let directory: URL
    private let maxBytes: Int
    private let ioQueue = DispatchQueue(label: "com.catch.diskImageCache", qos: .utility)
    private var writesSinceEviction = 0
    private let evictionInterval = 20

    init(subdirectory: String = "RemoteImages", maxBytes: Int = 150 * 1024 * 1024) {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directory = caches.appendingPathComponent(subdirectory, isDirectory: true)
        self.maxBytes = maxBytes
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Reads data from disk on a background queue. Returns nil on cache miss.
    func data(for key: String) async -> Data? {
        await withCheckedContinuation { continuation in
            ioQueue.async { [self] in
                let data = try? Data(contentsOf: filePath(for: key))
                continuation.resume(returning: data)
            }
        }
    }

    func store(_ data: Data, for key: String) {
        let path = filePath(for: key)
        ioQueue.async { [self] in
            try? data.write(to: path, options: .atomic)
            writesSinceEviction += 1
            if writesSinceEviction >= evictionInterval {
                writesSinceEviction = 0
                evictIfNeeded()
            }
        }
    }

    func remove(for key: String) {
        let path = filePath(for: key)
        ioQueue.async {
            try? FileManager.default.removeItem(at: path)
        }
    }

    func removeAll() {
        ioQueue.async { [self] in
            try? FileManager.default.removeItem(at: directory)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    private func filePath(for key: String) -> URL {
        let hash = sha256(key)
        return directory.appendingPathComponent(hash)
    }

    private static let hexChars = Array("0123456789abcdef".unicodeScalars)

    private func sha256(_ string: String) -> String {
        let digest = SHA256.hash(data: Data(string.utf8))
        var hex = String()
        hex.reserveCapacity(SHA256.byteCount * 2)
        for byte in digest {
            hex.unicodeScalars.append(Self.hexChars[Int(byte >> 4)])
            hex.unicodeScalars.append(Self.hexChars[Int(byte & 0x0F)])
        }
        return hex
    }

    private func evictIfNeeded() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }

        var entries: [(url: URL, size: Int, date: Date)] = []
        var totalSize = 0
        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let size = values.fileSize,
                  let date = values.contentModificationDate else { continue }
            entries.append((file, size, date))
            totalSize += size
        }

        guard totalSize > maxBytes else { return }

        // Evict oldest-written first (FIFO)
        entries.sort { $0.date < $1.date }
        for entry in entries {
            guard totalSize > maxBytes else { break }
            try? fm.removeItem(at: entry.url)
            totalSize -= entry.size
        }
    }
}

// MARK: - URLSession Configuration

private let cachedSession: URLSession = {
    let config = URLSessionConfiguration.default
    // Small HTTP cache for Cache-Control header support — our DiskImageCache
    // is the primary persistence layer, so keep URLCache lean to avoid double-caching
    config.urlCache = URLCache(
        memoryCapacity: 50 * 1024 * 1024,
        diskCapacity: 50 * 1024 * 1024
    )
    config.requestCachePolicy = .useProtocolCachePolicy
    return URLSession(configuration: config)
}()

// MARK: - Implementation

/// Thread-safe: `memoryCache` (NSCache) is internally synchronized;
/// `inFlightRequests` is guarded by `lock`.
final class RemoteImageCache: ImageCacheService, @unchecked Sendable {
    static let shared = RemoteImageCache()

    private static let maxConcurrentPrefetches = 4
    private static let maxPrefetchCount = 12

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache = DiskImageCache()

    /// Tracks in-flight downloads so concurrent requests for the same URL share one fetch.
    private var inFlightRequests: [String: Task<UIImage?, Never>] = [:]
    private let lock = NSLock()

    private init() {
        memoryCache.countLimit = 200
        memoryCache.totalCostLimit = 75 * 1024 * 1024 // 75 MB
    }

    /// Visible initializer for testing only.
    #if DEBUG
    init(countLimit: Int, totalCostLimit: Int) {
        memoryCache.countLimit = countLimit
        memoryCache.totalCostLimit = totalCostLimit
    }
    #endif

    /// Returns the image only if it's in the **memory** cache (synchronous, fast).
    /// Used in view init paths to avoid flicker — never blocks on disk I/O.
    func memoryImage(for key: String) -> UIImage? {
        memoryCache.object(forKey: key as NSString)
    }

    func removeImage(for key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        diskCache.remove(for: key)
    }

    func setImage(_ image: UIImage, for key: String) {
        setMemoryImage(image, for: key)
        if let jpegData = image.jpegData(compressionQuality: 0.85) {
            diskCache.store(jpegData, for: key)
        }
    }

    /// Stores an image with its original data — avoids re-encoding quality loss.
    func setImage(_ image: UIImage, data: Data, for key: String) {
        setMemoryImage(image, for: key)
        diskCache.store(data, for: key)
    }

    func removeAll() {
        memoryCache.removeAllObjects()
        diskCache.removeAll()
    }

    /// Returns a cached image or downloads it, checking memory → disk → network.
    /// Deduplicates concurrent requests for the same URL.
    /// - Parameters:
    ///   - urlString: The URL to fetch the image from.
    ///   - cacheKey: Optional stable identifier to use as cache key instead of the raw URL.
    ///     Use this when URLs may vary for the same logical image (query params, signed URLs).
    func loadImage(for urlString: String, cacheKey: String? = nil) async -> UIImage? {
        let key = cacheKey ?? urlString

        // L1: memory (fast, no I/O)
        if let memoryHit = memoryImage(for: key) { return memoryHit }

        // L2: disk (async, off main thread)
        if let data = await diskCache.data(for: key),
           let diskHit = UIImage(data: data) {
            setMemoryImage(diskHit, for: key)
            return diskHit
        }

        // L3: network — atomic check-and-set to prevent duplicate tasks
        let task: Task<UIImage?, Never> = lock.withLock {
            if let existing = inFlightRequests[key] { return existing }
            let newTask = Task<UIImage?, Never> {
                guard let url = URL(string: urlString),
                      let (data, response) = try? await cachedSession.data(from: url),
                      let http = response as? HTTPURLResponse,
                      200..<300 ~= http.statusCode,
                      let downloaded = UIImage(data: data) else {
                    self.lock.withLock { self.inFlightRequests[key] = nil }
                    return nil
                }
                self.setMemoryImage(downloaded, for: key)
                self.diskCache.store(data, for: key)
                self.lock.withLock { self.inFlightRequests[key] = nil }
                return downloaded
            }
            inFlightRequests[key] = newTask
            return newTask
        }
        return await task.value
    }

    /// Prefetches up to `maxPrefetchCount` images with bounded concurrency.
    /// Skips URLs already in memory — disk-only hits will be promoted to memory.
    func prefetch(urls: [String]) async {
        let uncached = Array(
            urls.lazy.filter { self.memoryImage(for: $0) == nil }.prefix(Self.maxPrefetchCount)
        )
        guard !uncached.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            var running = 0
            for urlString in uncached {
                if running >= Self.maxConcurrentPrefetches {
                    await group.next()
                    running -= 1
                }
                group.addTask {
                    _ = await self.loadImage(for: urlString)
                }
                running += 1
            }
        }
    }

    /// Returns JPEG data for the given URL, checking the cache first
    /// and falling back to a network fetch. Caches the image on a cache miss.
    func jpegData(for urlString: String, compressionQuality: CGFloat) async -> Data? {
        if let cached = memoryImage(for: urlString) {
            return cached.jpegData(compressionQuality: compressionQuality)
        }
        guard let downloaded = await loadImage(for: urlString) else {
            return nil
        }
        return downloaded.jpegData(compressionQuality: compressionQuality)
    }

    // MARK: - Private

    private func setMemoryImage(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
    }
}
