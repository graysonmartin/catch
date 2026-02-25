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
}
