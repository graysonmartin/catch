import Foundation
import Observation
@testable import CatchCore

@Observable
@MainActor
final class MockSupabaseAssetService: SupabaseAssetService {
    private(set) var uploadPhotoCalls: [(data: Data, bucket: SupabaseStorageBucket, ownerID: String, fileName: String)] = []
    private(set) var uploadPhotosCalls: [(photos: [Data], bucket: SupabaseStorageBucket, ownerID: String)] = []
    private(set) var deletePhotoCalls: [(bucket: SupabaseStorageBucket, path: String)] = []
    private(set) var publicURLCalls: [(bucket: SupabaseStorageBucket, path: String)] = []

    var uploadPhotoResult: String = "https://test.supabase.co/storage/v1/object/public/cat-photos/test.jpg"
    var uploadPhotosResult: [String] = []
    var errorToThrow: (any Error)?

    func uploadPhoto(
        _ data: Data,
        bucket: SupabaseStorageBucket,
        ownerID: String,
        fileName: String
    ) async throws -> String {
        uploadPhotoCalls.append((data, bucket, ownerID, fileName))
        if let error = errorToThrow { throw error }
        return uploadPhotoResult
    }

    func uploadPhotos(
        _ photos: [Data],
        bucket: SupabaseStorageBucket,
        ownerID: String
    ) async throws -> [String] {
        uploadPhotosCalls.append((photos, bucket, ownerID))
        if let error = errorToThrow { throw error }
        if !uploadPhotosResult.isEmpty { return uploadPhotosResult }
        return photos.enumerated().map { index, _ in
            "https://test.supabase.co/storage/v1/object/public/\(bucket.rawValue)/\(ownerID)/\(index).jpg"
        }
    }

    func deletePhoto(
        bucket: SupabaseStorageBucket,
        path: String
    ) async throws {
        deletePhotoCalls.append((bucket, path))
        if let error = errorToThrow { throw error }
    }

    func publicURL(
        bucket: SupabaseStorageBucket,
        path: String
    ) -> String {
        publicURLCalls.append((bucket, path))
        return "https://test.supabase.co/storage/v1/object/public/\(bucket.rawValue)/\(path)"
    }

    func reset() {
        uploadPhotoCalls = []
        uploadPhotosCalls = []
        deletePhotoCalls = []
        publicURLCalls = []
        uploadPhotoResult = "https://test.supabase.co/storage/v1/object/public/cat-photos/test.jpg"
        uploadPhotosResult = []
        errorToThrow = nil
    }
}
