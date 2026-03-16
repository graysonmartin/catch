import Foundation
import Observation
import Supabase
import os

/// Uploads and manages photos in Supabase Storage buckets.
@Observable
@MainActor
public final class DefaultSupabaseAssetService: SupabaseAssetService, @unchecked Sendable {
    private let clientProvider: any SupabaseClientProviding
    private let logger = Logger(
        subsystem: "com.graysonmartin.catch",
        category: "SupabaseAssetService"
    )

    private static let jpegCompressionQuality: Double = 0.7
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

        return publicURL(bucket: bucket, path: path)
    }

    public func uploadPhotos(
        _ photos: [Data],
        bucket: SupabaseStorageBucket,
        ownerID: String
    ) async throws -> [String] {
        try await withThrowingTaskGroup(of: (Int, String).self, returning: [String].self) { group in
            for (index, photoData) in photos.enumerated() {
                group.addTask {
                    let fileName = "\(UUID().uuidString)_\(index).jpg"
                    let url = try await self.uploadPhoto(
                        photoData,
                        bucket: bucket,
                        ownerID: ownerID,
                        fileName: fileName
                    )
                    return (index, url)
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
        try await clientProvider.client.storage
            .from(bucket.rawValue)
            .remove(paths: [path])
    }

    public func publicURL(
        bucket: SupabaseStorageBucket,
        path: String
    ) -> String {
        let baseURL = SupabaseConfig.url.absoluteString
        return "\(baseURL)/storage/v1/object/public/\(bucket.rawValue)/\(path)"
    }
}
