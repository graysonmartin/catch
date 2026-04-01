import Foundation
import CatchCore

@MainActor
final class MockSupabaseAssetService: SupabaseAssetService {
    private(set) var uploadPhotoCalls: [(data: Data, bucket: SupabaseStorageBucket, ownerID: String, fileName: String)] = []
    private(set) var uploadPhotosCalls: [(photos: [Data], bucket: SupabaseStorageBucket, ownerID: String)] = []
    private(set) var deletePhotoCalls: [(bucket: SupabaseStorageBucket, path: String)] = []

    var errorToThrow: (any Error)?

    func uploadPhoto(_ data: Data, bucket: SupabaseStorageBucket, ownerID: String, fileName: String) async throws -> String {
        uploadPhotoCalls.append((data, bucket, ownerID, fileName))
        if let error = errorToThrow { throw error }
        return "https://example.com/\(fileName)"
    }

    func uploadPhotos(_ photos: [Data], bucket: SupabaseStorageBucket, ownerID: String) async throws -> [String] {
        uploadPhotosCalls.append((photos, bucket, ownerID))
        if let error = errorToThrow { throw error }
        return photos.indices.map { "https://example.com/photo_\($0).jpg" }
    }

    func deletePhoto(bucket: SupabaseStorageBucket, path: String) async throws {
        deletePhotoCalls.append((bucket, path))
        if let error = errorToThrow { throw error }
    }

    func publicURL(bucket: SupabaseStorageBucket, path: String) -> String {
        "https://example.com/\(path)"
    }
}
