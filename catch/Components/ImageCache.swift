import UIKit
import CommonCrypto

// MARK: - Protocol

protocol ImageCacheService: Sendable {
    func image(for key: String) -> UIImage?
    func setImage(_ image: UIImage, for key: String)
    func removeImage(for key: String)
    func removeAll()
}

// MARK: - Disk Cache

private final class DiskImageCache: @unchecked Sendable {

    private let directory: URL
    private let maxBytes: Int
    private let ioQueue = DispatchQueue(label: "com.catch.diskImageCache", qos: .utility)

    init(subdirectory: String = "RemoteImages", maxBytes: Int = 150 * 1024 * 1024) {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directory = caches.appendingPathComponent(subdirectory, isDirectory: true)
        self.maxBytes = maxBytes
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Reads data from disk asynchronously on a background queue.
    func data(for key: String) async -> Data? {
        await withCheckedContinuation { continuation in
            ioQueue.async { [self] in
                let path = filePath(for: key)
                guard FileManager.default.fileExists(atPath: path.path) else {
                    continuation.resume(returning: nil)
                    return
                }
                // Touch access date for LRU eviction
                try? FileManager.default.setAttributes(
                    [.modificationDate: Date()],
                    ofItemAtPath: path.path
                )
                let data = try? Data(contentsOf: path)
                continuation.resume(returning: data)
            }
        }
    }

    func store(_ data: Data, for key: String) {
        let path = filePath(for: key)
        ioQueue.async { [self] in
            try? data.write(to: path, options: .atomic)
            evictIfNeeded()
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

    private func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
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

        // Evict oldest-accessed first
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
    // 200 MB disk / 50 MB memory HTTP cache — supplements our own disk cache
    // for honoring server cache-control headers
    config.urlCache = URLCache(
        memoryCapacity: 50 * 1024 * 1024,
        diskCapacity: 200 * 1024 * 1024
    )
    config.requestCachePolicy = .useProtocolCachePolicy
    return URLSession(configuration: config)
}()

// MARK: - Implementation

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
    func image(for key: String) -> UIImage? {
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

    func removeAll() {
        memoryCache.removeAllObjects()
        diskCache.removeAll()
    }

    /// Returns a cached image or downloads it, checking memory → disk → network.
    /// Deduplicates concurrent requests for the same URL.
    func loadImage(for urlString: String) async -> UIImage? {
        // L1: memory (fast, no I/O)
        if let memoryHit = image(for: urlString) { return memoryHit }

        // L2: disk (async, off main thread)
        if let data = await diskCache.data(for: urlString),
           let diskHit = UIImage(data: data) {
            setMemoryImage(diskHit, for: urlString)
            return diskHit
        }

        // L3: network (deduplicated)
        let existingTask: Task<UIImage?, Never>? = lock.withLock {
            inFlightRequests[urlString]
        }
        if let task = existingTask {
            return await task.value
        }

        let task = Task<UIImage?, Never> {
            guard let url = URL(string: urlString),
                  let (data, response) = try? await cachedSession.data(from: url),
                  let http = response as? HTTPURLResponse,
                  200..<300 ~= http.statusCode,
                  let downloaded = UIImage(data: data) else {
                lock.withLock { inFlightRequests[urlString] = nil }
                return nil
            }
            setMemoryImage(downloaded, for: urlString)
            diskCache.store(data, for: urlString)
            lock.withLock { inFlightRequests[urlString] = nil }
            return downloaded
        }

        lock.withLock { inFlightRequests[urlString] = task }
        return await task.value
    }

    /// Prefetches up to `maxPrefetchCount` images with bounded concurrency.
    /// Skips URLs already in the memory cache.
    func prefetch(urls: [String]) async {
        let uncached = Array(urls.lazy.filter { self.image(for: $0) == nil }.prefix(Self.maxPrefetchCount))
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
        if let cached = image(for: urlString) {
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
