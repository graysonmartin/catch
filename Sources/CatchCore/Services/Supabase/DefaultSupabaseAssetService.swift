import Foundation
import Supabase
import os

/// Uploads and manages photos in Supabase Storage buckets.
@MainActor
public final class DefaultSupabaseAssetService: SupabaseAssetService, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private let logger = Logger(
        subsystem: "com.graysonmartin.catch",
        category: "SupabaseAssetService"
    )

    private static let contentType = "image/jpeg"

    public init(clientProvider: any SupabaseClientProviding) {
        self.clientProvider = clientProvider
    }

    // MARK: - SupabaseAssetService

    public func uploadPhoto(
        _ data: Data,
        bucket: SupabaseStorageBucket,
        ownerID: String,
        fileName: String
    ) async throws -> String {
        let path = "\(ownerID)/\(fileName)"

        try await clientProvider.client.storage
            .from(bucket.rawValue)
            .upload(
                path: path,
                file: data,
                options: FileOptions(contentType: Self.contentType, upsert: true)
            )

        return Self.buildPublicURL(bucket: bucket, path: path)
    }

    public func uploadPhotos(
        _ photos: [Data],
        bucket: SupabaseStorageBucket,
        ownerID: String
    ) async throws -> [String] {
        let client = clientProvider.client
        let contentType = Self.contentType

        return try await withThrowingTaskGroup(of: (Int, String).self, returning: [String].self) { group in
            for (index, photoData) in photos.enumerated() {
                group.addTask {
                    let baseName = "\(UUID().uuidString)_\(index)"
                    let fileName = "\(baseName).jpg"
                    let path = "\(ownerID)/\(fileName)"

                    // Upload full image
                    try await client.storage
                        .from(bucket.rawValue)
                        .upload(
                            path: path,
                            file: photoData,
                            options: FileOptions(contentType: contentType, upsert: true)
                        )

                    // Upload thumbnail (best-effort — don't fail the whole upload if thumb fails)
                    if let thumbData = ThumbnailGenerator.generateThumbnail(from: photoData),
                       let thumbPath = ThumbnailURL.thumbnailURL(for: path) {
                        do {
                            try await client.storage
                                .from(bucket.rawValue)
                                .upload(
                                    path: thumbPath,
                                    file: thumbData,
                                    options: FileOptions(contentType: contentType, upsert: true)
                                )
                        } catch {
                            Logger(subsystem: "com.graysonmartin.catch", category: "SupabaseAssetService")
                                .warning("Thumbnail upload failed for \(thumbPath): \(error.localizedDescription)")
                        }
                    }

                    return (index, Self.buildPublicURL(bucket: bucket, path: path))
                }
            }

            var results = Array(repeating: "", count: photos.count)
            for try await (index, url) in group {
                results[index] = url
            }
            return results
        }
    }

    public func deletePhoto(
        bucket: SupabaseStorageBucket,
        path: String
    ) async throws {
        // Also delete the thumbnail variant if it exists
        var paths = [path]
        if let thumbPath = ThumbnailURL.thumbnailURL(for: path) {
            paths.append(thumbPath)
        }
        try await clientProvider.client.storage
            .from(bucket.rawValue)
            .remove(paths: paths)
    }

    public func publicURL(
        bucket: SupabaseStorageBucket,
        path: String
    ) -> String {
        Self.buildPublicURL(bucket: bucket, path: path)
    }

    // MARK: - Private

    private nonisolated static func buildPublicURL(bucket: SupabaseStorageBucket, path: String) -> String {
        let baseURL = SupabaseConfig.url.absoluteString
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return "\(baseURL)/storage/v1/object/public/\(bucket.rawValue)/\(encodedPath)"
    }
}
