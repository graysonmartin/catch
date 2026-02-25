import CloudKit

enum CloudKitAssetManager {
    static func writePhotoAssets(_ photos: [Data]) throws -> [CKAsset] {
        let tempDir = FileManager.default.temporaryDirectory
        return try photos.enumerated().map { index, data in
            let url = tempDir.appendingPathComponent("catsync_\(UUID().uuidString)_\(index).jpg")
            try data.write(to: url)
            return CKAsset(fileURL: url)
        }
    }

    static func cleanupTempFiles(_ assets: [CKAsset]) {
        for asset in assets {
            if let url = asset.fileURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    static func loadPhotoData(from assets: [CKAsset]?) async -> [Data] {
        guard let assets else { return [] }
        return assets.compactMap { asset in
            guard let url = asset.fileURL else { return nil }
            return try? Data(contentsOf: url)
        }
    }

    static func loadAllPhotos(from records: [CKRecord]) async -> [[Data]] {
        await withTaskGroup(of: (Int, [Data]).self, returning: [[Data]].self) { group in
            for (index, record) in records.enumerated() {
                let assets = record["photos"] as? [CKAsset]
                group.addTask {
                    (index, await loadPhotoData(from: assets))
                }
            }
            var results = Array(repeating: [Data](), count: records.count)
            for await (index, photos) in group {
                results[index] = photos
            }
            return results
        }
    }
}
